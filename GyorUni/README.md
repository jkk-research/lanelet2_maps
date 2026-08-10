# Győr University Campus lanelet

![alt text](GyorUni.png)

## Versions

### 2026-07-20 (latest)

Transformed `2026.01.16.` with:
- `t_x` : `+0.97`m 
- `t_y` : `-0.33`m 
- `yaw` : `+0.33`°


### 2026-01-16 
First version. Version is defined by date, which is in ISO 8601 standard `YYYY-MM-DD`.


# Győr University Campus pointcloud

Transforming **2026-01-16** verison with +0.97m, -0.33m, +0.33° (0.0057595865rad):

```c
pcl_transform_point_cloud \
  /home/dev/autoware_map/gyor_campus/pointcloud_map_orig.pcd \
  /home/dev/autoware_map/gyor_campus/pointcloud_map.pcd \
  -trans 0.970,-0.330,0 \
  -axisangle 0,0,1,0.0057595865
```

TODO
