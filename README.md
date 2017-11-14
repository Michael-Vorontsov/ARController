# ARController

Idea is to provide to AR and Scene kit mechanism similar to  ViewController. Usually several application consist of several subsequent phases, or scenes. 
Each scene happened insed same environment, sessions and objects however interactions between them, user actions and UI can vary.


## Overview

For example in first scene usar can define surfaces, in second state layout objects, and in third launch and controll interactions between them.

Ideas is to define sequence of Controllers that handling behaviour of 3D world. 

View controller host ARSNView and can setup main features such as camera resolution, frame rate etc.

It controls SceneControllers, and inject scene view in them. 

SceneControllers hosting scene and managing node graph within. 

As basic fatures and scene view itself controlled by parent view controller, there is no interruption in transit between scenes. 

Scene Controllers responsible for handling user gestures, translating 2D screen coorinates into 3D scene world, creating, deleting and animating nodes.
 
The nodes of significant importance can be controlled by Node Controllers. One of example of interaction is drag and drop. Scene controller responsible for handling  pan gestures, however node controller responsible for allowing to drag objects to and from controlled nodes.

Described functionality delivered by set of Protocols oriented extensions and bas classes. 

Most of scene controllers can be constructed using conformance to protocols and gaining their extensions. 

## Getting Started

ARKit is available on any iOS 11 device, but the world tracking features that enable high-quality AR experiences require a device with the A9 or later processor.

## Example

Sample application based on apple ARKit sample. In consist of 3 stages: 
	1. Plane layout - press button next to proceed further
	2. Objects placement - user can place several several objects and interact with them. Please pay attention to ChipStacks - thet placed with random count of chips in them. User can move chips between stacks by drag&drop them. Only another stack of chips can accept dragging chips. Place 3 stacks of chips to proceed further. Please see how chips following finger. Keep dragging object (hovering) over another stack and observe transparent chip on top of it. 
	3. Object interactions. Please drag&drop chips between stacks. 
	
## Components 

### Nodes

#### Plane 

Object to describe horizontal planes. Planes can be placed automatically by make SceneController conforms to PlaneConstructing protocol (extension will do most of the job automatically). 

Planes read settings keys from user defaults, drawing occlusion plane, or debug visuals.

#### VirtualObject

Basic primitive to place interactive objects. Set to NodeController  to control it. 

### Protocols

This is Protocol-Oriented extension deliver capabilities by composing protocols. 

#### NodeControlling 

Mark NodeController

#### NodeConrollable 

Mark subjects of node controllers. 

#### SimpleObjectTracking

For simple object tracking. In combination with PanGestureRecognisable provides tracking pan gestures on objects and forwarding, to drag&drop between objects, however do not following dragged object in 3D environment.

#### SceneObjectTracking

Power ability to transform screen 2d  coordinate into 3d AR coordinate based on current frame, add and move objects around etc. In combination with PanGestureRecognisable provides tracking pan gesture for draggin object around 3D world, including drag&drop.

#### Plane Constructing

Allowing to construct and update planes according to AR rendering

####  PanGestureRecognisable

Provides set of methods to process pan gesture to interact with objects (drag&drop). 
Current Swift can't create gesture recogniser with non-obj-c action handlers. Call processPanGestureAction with gesture recogniser to process drag&drop.
	
### Utilities 

Set of helpers and extensions to power hit tests, 2d to 3d world transition, etc. 

#### TextManager 

Convenient set of classes and interfaces to report errors, user messages etc.

### SceneHelpers

Set helper classes, suc as `FocusSquare`, that draws a square outline in the AR view, giving the user hints about the status of ARKit world tracking. The square changes size to reflect estimated scene depth, and switches between open and closed states with a "lock" animation to indicate whether ARKit has detected a plane suitable for placing an object. 

## Feedback

Any feedback will be appreciated. 

(c) 2017 Michael Vorontsov

