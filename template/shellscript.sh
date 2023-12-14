#!/bin/bash

master_count=3
data_count=2
master_host_prefix="es-master-host-test"
priv_dns_zone="dev.nl.cjscp.org.uk"
data_host_prefix="es-data-host-test"
master_node_list=()
data_node_list=()

echo "Master node Count: $master_count"
echo "Data node Count $data_count"
echo "     "
for (( y=0; y<$master_count; y++  ))
do
  master_node_list+=($master_host_prefix-$y.$priv_dns_zone, )
done
echo [ ${master_node_list[@]} ]

for (( x=0 ; x<$data_count; x++  ))
do
  data_node_list+=($data_host_prefix-$x.$priv_dns_zone, )
done
echo [ ${data_node_list[@]} ]


echo "-------"
echo -ne "cluster.initial_master_nodes: "; echo [ ${master_node_list[@]} ]
cluster_node_list=${master_node_list[@]}
discovery_node_list=${data_node_list[@]}
echo "-------- $list -----"
sed -i "s/^cluster.initial_master_nodes:,*/cluster.initial_master_nodes: [ $cluster_node_list ]/g" /home/packer/file.yml
sed -i "s/^discovery.seed_hosts:,*/discovery.seed_hosts: [ $cluster_node_list $discovery_node_list ]/g" /home/packer/file.yml