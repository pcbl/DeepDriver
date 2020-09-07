# -*- coding: utf-8 -*-
"""
Created on Mon Jun 22 22:09:46 2020

@author: polg
"""


import glob
import os
import sys
# ==============================================================================
# -- Find CARLA module ---------------------------------------------------------
# ==============================================================================
try:
    sys.path.append(glob.glob('../../carla/dist/carla-*%d.%d-%s.egg' % (
        sys.version_info.major,
        sys.version_info.minor,
        'win-amd64' if os.name == 'nt' else 'linux-x86_64'))[0])
except IndexError:
    pass

# ==============================================================================
# -- Add PythonAPI for release mode --------------------------------------------
# ==============================================================================
try:
    sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + '/carla')
except IndexError:
    pass

import carla
import numpy as np
import cv2
import threading
from carla import ColorConverter as cc
IM_WIDTH = 640
IM_HEIGHT = 480

def process_img(image, sensor_data):
    if sensor_data[0].startswith('sensor.lidar'):        
        lidar_range = 2.0*float(50)
        points = np.frombuffer(image.raw_data, dtype=np.dtype('f4'))
        points = np.reshape(points, (int(points.shape[0] / 4), 4))
        lidar_data = np.array(points[:, :2])
        lidar_data *= IM_HEIGHT / lidar_range
        lidar_data += (0.5 * IM_WIDTH, 0.5 * IM_HEIGHT)
        lidar_data = np.fabs(lidar_data)  # pylint: disable=E1111
        lidar_data = lidar_data.astype(np.int32)
        lidar_data = np.reshape(lidar_data, (-1, 2))
        lidar_img_size = (IM_WIDTH, IM_HEIGHT, 3)
        lidar_img = np.zeros((lidar_img_size), dtype=np.uint8)
        img_to_show = lidar_img.swapaxes(0, 1)                
    else:
        image.convert(sensor_data[1])
        i = np.array(image.raw_data)
        i2 = i.reshape((IM_HEIGHT, IM_WIDTH, 4))
        i3 = i2[:, :, :3]
        i3 = i3[:, :, ::-1]
        img_to_show = i3
        
    sensor_data[3].acquire()
    try:
        cv2.imshow(sensor_data[2], img_to_show)    
        cv2.waitKey(1)
    finally:
        sensor_data[3].release() # release lock, no matter what   
    

def canny(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (5,5), 0)
    canny = cv2.Canny(blur,50,150)
    return canny

def display_lines(image, lines):
    line_image = np.zeros_like(image)
    if lines is not None:
        for x1, y1, x2, y2 in lines:           
           cv2.line(line_image, (x1,y1), (x2,y2), (255,0,0), 10)
    return line_image

def make_coordinates(image,line_parameters):
    slope, intercept = line_parameters
    y1 = image.shape[0]
    y2 = int(y1 * 3 / 5)
    x1 = int((y1 - intercept)/slope)
    x2 = int((y2 - intercept)/slope)
    return np.array([x1,y1,x2,y2])   

def average_slope_intercept(image, lines):
    left_fit = []
    right_fit = []
    for line in lines:
        x1, y1, x2, y2 = line.reshape(4)
        parameters = np.polyfit((x1,x2),(y1,y2),1)
        slope = parameters[0]
        intercept = parameters[1]
        if slope < 0:
            left_fit.append((slope,intercept))
        else:
            right_fit.append((slope,intercept))            
    averaged_lines = []
    
    if len(left_fit):
        left_fit_average = np.average(left_fit, axis=0)
        left_line = make_coordinates(image, left_fit_average)
        averaged_lines.append(left_line)
    
    if len(right_fit):        
        right_fit_average = np.average(right_fit, axis=0)
        right_line = make_coordinates(image, right_fit_average)
        averaged_lines.append(right_line)
    return averaged_lines        

def region_of_interest(image):
    height = image.shape[0]
    polygons = np.array([
        #Our Triangle
        [(0, height), (0,height-120),(320,240),(640,height-120), (640, height)]
        ])
    #create a mask(black[zeros...])
    mask = np.zeros_like(image)
    #Then we fill the polygon(our triangle) with white...
    cv2.fillPoly(mask, polygons, 255)    
    #runnign bitwise to ignore everything which is out of our mask
    masked_image = cv2.bitwise_and(image,mask)    
    return masked_image

def detect_lanes(raw_image):
    i = np.array(raw_image.raw_data)
    i2 = i.reshape((IM_HEIGHT, IM_WIDTH, 4))
    frame_image = i2[:, :, :3]    
    canny_image = canny(frame_image)
    cropped_image = region_of_interest(canny_image)    
    #Hough Tranform to detect lines
    lines = cv2.HoughLinesP(cropped_image, 2, np.pi/180, 100, np.array([]), minLineLength=40, maxLineGap=5)    
    if lines is None:
        combo_image= frame_image
    else:
        #Taking one left and right line by averaging the found lines into a single 1
        averaged_lines = average_slope_intercept(frame_image, lines)
        #Then we create an image with the lines
        line_image = display_lines(frame_image, averaged_lines)
        #And wwe add some overlay on top of the original image
        combo_image = cv2.addWeighted(frame_image, 0.8, line_image, 1, 1)
    cv2.imshow('lanes',combo_image)    
    # wait 1 millisecond or until q is pressed
    if cv2.waitKey(1) == ord('q'):        
        destroy_and_quit()        
 
def destroy_and_quit():
    print('destroying actors')
    for actor in actor_list:
        actor.destroy()
    print('done.')       
    os._exit(0) 

actor_list = []
try:
    client = carla.Client('deepdriver.westeurope.cloudapp.azure.com', 2000)
    client.set_timeout(2.0)

    world = client.get_world()

    blueprint_library = world.get_blueprint_library()

    bp = blueprint_library.filter('model3')[0]
    print(bp)

    spawn_point = world.get_map().get_spawn_points()[5]

    vehicle = world.spawn_actor(bp, spawn_point)
        
    vehicle.set_autopilot(True)  # if you just wanted some NPCs to drive.

    actor_list.append(vehicle)
    
    # Adjust sensor relative to vehicle
    spawn_point = carla.Transform(carla.Location(x=2.5, z=0.7))
    
    '''
    sensors = [
            ['sensor.camera.rgb', cc.Raw, 'RGB', threading.RLock()],
          #  ['sensor.camera.depth', cc.Raw, 'Depth_Raw', threading.RLock()],
            #['sensor.camera.depth', cc.Depth, 'Depth_Gray)', threading.RLock()],
            #['sensor.camera.depth', cc.LogarithmicDepth, 'Depth_Log', threading.RLock()],
            #['sensor.camera.semantic_segmentation', cc.Raw, 'Segmentation_Raw', threading.RLock()],
            #['sensor.camera.semantic_segmentation', cc.CityScapesPalette,'Segmentation_CityScapes', threading.RLock()],
            #['sensor.lidar.ray_cast', None, 'Lidar', threading.Lock()]
            ]
    
    for sensor in sensors:
        sensor_blue_print = blueprint_library.find(sensor[0])
        if sensor[0].startswith('sensor.camera'):
            sensor_blue_print.set_attribute('image_size_x', str(IM_WIDTH))
            sensor_blue_print.set_attribute('image_size_y', str(IM_HEIGHT))
            if sensor_blue_print.has_attribute('gamma'):
                sensor_blue_print.set_attribute('gamma', str(2.2))#default game 2.2...
        elif sensor[0].startswith('sensor.lidar'):
            sensor_blue_print.set_attribute('range', '50')
        #sensor_blue_print.set_attribute('fov', '110') # Field of View
        sensor_blue_print.set_attribute('sensor_tick', '0')  
        sensor_instance = world.spawn_actor(sensor_blue_print, spawn_point, attach_to=vehicle)
        actor_list.append(sensor_instance)# Add to this list to remove later
        sensor_instance.listen(lambda data: process_img(data,sensor))            
'''
    # https://carla.readthedocs.io/en/latest/cameras_and_sensors
    # get the blueprint for this sensor
    lanesCamera = blueprint_library.find('sensor.camera.rgb')
    # change the dimensions of the image
    lanesCamera.set_attribute('image_size_x', f'{IM_WIDTH}')
    lanesCamera.set_attribute('image_size_y', f'{IM_HEIGHT}')
    lanesCamera.set_attribute('fov', '110')
    lanesCamera.set_attribute('sensor_tick', '0')
    
    
    # spawn the sensor and attach to vehicle.
    lanesCameraSensor = world.spawn_actor(lanesCamera, spawn_point, attach_to=vehicle)

    # add sensor to list of actors
    actor_list.append(lanesCameraSensor)

    # do something with this sensor
    lanesCameraSensor.listen(lambda data: detect_lanes(data))

    while True:      
        # As soon as the server is ready continue!
     #   vehicle.apply_control(carla.VehicleControl(throttle=.2, steer=0.0))
        if not world.wait_for_tick(1):
            continue
        # as soon as the server is ready continue!
        world.wait_for_tick(1)

finally:
    print('destroying actors')
    for actor in actor_list:
        actor.destroy()
    print('done.')