# Godot-GDScript-Objects
Various 2D and 3D programs created using GDScript, a dynamically typed, Python-like programming language for the Godot game engine.

An AStar program for the Godot game engine's GDScript resides in Player3D.gd.  I created a graph of junctions for moving between rooms in a house.   At each iteration, the AI moves to the graph's minimum cost node to get to its moving target (the player or another AI).  The cost of a target is determined by that node's distance from the AI in addition to the goal's heuristic cost calculated as the sum horizontal and vertical distance from the AI to its target.
