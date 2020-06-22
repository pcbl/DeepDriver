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
import random
import time
import numpy as np
import cv2

IM_WIDTH = 640
IM_HEIGHT = 480

def process_img(image):
    i = np.array(image.raw_data)
    i2 = i.reshape((IM_HEIGHT, IM_WIDTH, 4))
    i3 = i2[:, :, :3]
    cv2.imshow("", i3)
    cv2.waitKey(1)
    return i3/255.0



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
        cv2.imshow('lanes',frame_image)    
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
    client = carla.Client('13.93.27.227', 2000)
    client.set_timeout(2.0)

    world = client.get_world()

    blueprint_library = world.get_blueprint_library()

    bp = blueprint_library.filter('model3')[0]
    print(bp)

    spawn_point = world.get_map().get_spawn_points()[5]

    vehicle = world.spawn_actor(bp, spawn_point)
        
    #vehicle.set_autopilot(True)  # if you just wanted some NPCs to drive.

    actor_list.append(vehicle)
    

    # https://carla.readthedocs.io/en/latest/cameras_and_sensors
    # get the blueprint for this sensor
    blueprint = blueprint_library.find('sensor.camera.rgb')
    # change the dimensions of the image
    blueprint.set_attribute('image_size_x', f'{IM_WIDTH}')
    blueprint.set_attribute('image_size_y', f'{IM_HEIGHT}')
    blueprint.set_attribute('fov', '110')
    blueprint.set_attribute('sensor_tick', '0')
    

    # Adjust sensor relative to vehicle
    spawn_point = carla.Transform(carla.Location(x=2.5, z=0.7))

    # spawn the sensor and attach to vehicle.
    sensor = world.spawn_actor(blueprint, spawn_point, attach_to=vehicle)

    # add sensor to list of actors
    actor_list.append(sensor)

    # do something with this sensor
    sensor.listen(lambda data: detect_lanes(data))

   # vehicle.apply_control(carla.VehicleControl(throttle=0.5, steer=0.0))
 #   time.sleep(5)
 #   vehicle.apply_control(carla.VehicleControl(throttle=.3, steer=1.0))
  #  time.sleep(5)
  #  vehicle.apply_control(carla.VehicleControl(throttle=.5, steer=0))

    while True:      
        # As soon as the server is ready continue!
        vehicle.apply_control(carla.VehicleControl(throttle=.2, steer=0.0))
        if not world.wait_for_tick(1):
            continue
        # as soon as the server is ready continue!
        world.wait_for_tick(1)

finally:
    print('destroying actors')
    for actor in actor_list:
        actor.destroy()
    print('done.')