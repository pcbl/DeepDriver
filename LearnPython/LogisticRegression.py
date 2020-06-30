# -*- coding: utf-8 -*-
"""
Created on Thu Jun 25 21:57:33 2020

@author: polg
"""
import numpy as np
import matplotlib.pyplot as plt

def draw(x1,x2):    
    ln = plt.plot(x1,x2)
    plt.pause(0.0001)
    ln[0].remove()#removing previous one

def sigmoid(score):
    return 1/(1 + np.exp(-score))

def calculate_error(line_parameters, points, y):    
    m = points.shape[0]#Number of points
    p = sigmoid(points * line_parameters)
    cross_entropy = -(1/m) * (np.log(p).T * y + np.log(1-p).T * (1-y))
    return cross_entropy

def gradient_descent (line_parameters, points, y, learning_rate):
    m = points.shape[0]
    for i in range(500):
        p = sigmoid(points * line_parameters)
        gradient = (points.T * (p - y))*(learning_rate/m)
        line_parameters = line_parameters - gradient
        w1 = line_parameters.item(0)
        w2 = line_parameters.item(1)
        b  = line_parameters.item(2)
        x1 = np.array([points[:, 0].min(), points[:, 0].max()])
        x2 = -b / w2 + x1 * (-w1 / w2)        
        draw(x1,x2)
        print(calculate_error(line_parameters, points, y))
    
    
n_pts = 100
bias = np.ones(n_pts)
#here we get always the same random values... by fixing the seed
np.random.seed(0)

#T is the tranpose, to flip rows to columns...
top_region = np.array([
    #10 is the center of out normal distribution, 2 is std. deviation
    np.random.normal(10, 2, n_pts), 
    np.random.normal(12, 2, n_pts),
    bias]).T
bottom_region = np.array([
    np.random.normal(5, 2, n_pts), 
    np.random.normal(6, 2, n_pts),
    bias]).T
all_points = np.vstack((top_region,bottom_region))

#Now we start with 0 and wil use gradient descent to find the optimal line
line_parameters = np.matrix([np.zeros(3)]).T

#Label for error
#first(0's) n_pts are the top(red=0)
#second(1's) n_pts are the bottom(blue=1)
y = np.array([np.zeros(n_pts), np.ones(n_pts)]).reshape(n_pts*2,1)    

#Plotting!
_, ax = plt.subplots(figsize=(4,4))
ax.scatter(top_region[:, 0],top_region[:, 1], color='red')
ax.scatter(bottom_region[:, 0],bottom_region[:, 1], color='blue')
#draw(x1,x2)
gradient_descent(line_parameters, all_points, y, 0.06)
#plt.show()