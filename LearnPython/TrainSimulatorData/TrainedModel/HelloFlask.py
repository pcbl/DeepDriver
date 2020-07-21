# -*- coding: utf-8 -*-
"""
Created on Tue Jul 21 22:44:12 2020

@author: polg
"""

# Before Running:
#conda create --name simulator
#conda activate simulator
# conda install -c conda-forge python=3.7
# conda install -c anaconda flask

from flask import Flask

app = Flask(__name__) #'__main__'

@app.route('/home')
def greeting():
    return 'Welcome!'

if __name__ == '__main__':
    app.run(port=3000)    