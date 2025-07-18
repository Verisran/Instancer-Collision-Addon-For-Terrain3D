## If unfamiliar with the Terrain3D addon, see first
Terrain3D GitHub: https://github.com/TokisanGames/Terrain3D

Terrain3D documentation: https://terrain3d.readthedocs.io/en/stable/

# Disclaimer:
## Terrain3D already has a official [collision PR](https://github.com/TokisanGames/Terrain3D/pull/699)

# Instancer Collision Generation
This Node aims to extend the capabilities of the Terrain3D addon by TokinsanGames by generating collisions for Mesh Instances.

[Terrain3D Docs: Instancer - no-collision](https://terrain3d.readthedocs.io/en/stable/docs/instancer.html#no-collision)

As described in the above part of the T3D documentation, as of version 1.0.1 there is no collision for instanced meshes, so I took it upon myself to create this for my own project.

This single node works alongside the main Terrain3D node in your scene in a plug and play fashion, reading your asset mesh files and extracting the first CollisionShape in each asset that it finds.
It uses the PhysicsServer3D to instance one giant static body that holds all the shapes instanced meshes with the appropriate tranforms to match their in game locations.


# How to use
[Example Video](https://www.youtube.com/watch?v=Nw9YCPa2G0A&feature=youtu.be)

All that this node needs is reference to the Terrain3D node to be set in the editor as show below. It will instance the collider as soon as it enters the scene.

<img width="317" height="321" alt="image" src="https://github.com/user-attachments/assets/54a6a8df-037e-4a3e-8fbb-b3c57c24f270" />  <img width="265" height="60" alt="image" src="https://github.com/user-attachments/assets/c1f611d0-ae31-492e-a99e-c5d0dfb30877" />

Similar to how Terrain3D handles its Instancer LOD system, it reads the mesh asset file and checks if there is a CollisionShape3D with a shape for each mesh asset.
#### Example Structure of mesh asset:
<img width="1913" height="900" alt="T3DIC_example" src="https://github.com/user-attachments/assets/eb99311c-6f5e-4401-aafd-1c40171b9392" />

thats all!
