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
from keras.models import load_model
IM_WIDTH = 320
IM_HEIGHT = 160

def img_preprocess(img, vehicle, model):

    npimp = np.array(img.raw_data)

    frame_image = npimp.reshape((IM_HEIGHT, IM_WIDTH, 4))
    cv2.imshow('img', frame_image)

    frame_image = cv2.cvtColor(frame_image, cv2.COLOR_RGB2YUV)

    frame_image = frame_image[60:135, :, :]

    frame_image = cv2.GaussianBlur(frame_image, (3, 3), 0)
    frame_image = cv2.resize(frame_image, (200, 66))

    frame_image = frame_image / 255.0

    frame_image = np.array([frame_image])

    steering_angle = float(model.predict(frame_image))
    print("#################### steering angle")
    print(steering_angle)

#    vehicle.apply_control(carla.VehicleControl(throttle=.5, steer=steering_angle))
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
    model = load_model('model.h5')
    print(model.summary())
    world = client.get_world()

    blueprint_library = world.get_blueprint_library()

    bp = blueprint_library.filter('model3')[0]
    print(bp)

    spawn_point = world.get_map().get_spawn_points()[7]

    vehicle = world.spawn_actor(bp, spawn_point)
        
    vehicle.set_autopilot(True)  # if you just wanted some NPCs to drive.

    actor_list.append(vehicle)
    
    # Adjust sensor relative to vehicle
    spawn_point = carla.Transform(carla.Location(x=2.5, z=0.7))

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
    lanesCameraSensor.listen(lambda data: img_preprocess(data,vehicle,model))

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