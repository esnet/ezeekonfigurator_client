module eZeeKonfigurator;

@load base/frameworks/cluster

@load ./options

@if ( !Cluster::is_enabled() || ( Cluster::is_enabled() && Cluster::local_node_type() == Cluster::MANAGER ) )
@load ./communication
@endif
