@load base/frameworks/config

module eZeeKonfigurator;

@load ./options

export {

    ## The brokerd peer we connect to
    option brokerd_peer: set[string] = {};

    ## Our unique identifier
    option uuid: string = "";

}

# The list of brokerd server(s) that we connect to.
global brokerd_servers: set[addr, port] = {};

## This manages creating/removing our brokerd peerings
function update_brokerd_peer(ID: string, new_value: set[string]): set[string]
{
    local cur_value: set[string] = lookup_ID(ID);
    local parts: string_vec;

    local new_vals: set[string] = new_value - cur_value;
    local old_vals: set[string] = cur_value - new_value;

    for (new in new_vals)
    {
        parts = split_string1(new, /_/);
        Broker::peer(parts[0], to_port(parts[1]));
        add brokerd_servers[to_addr(parts[0]), to_port(parts[1])];
    }

    for (old in old_vals)
    {
        parts = split_string1(old, /_/);
        Broker::unpeer(parts[0], to_port(parts[1]));
        delete brokerd_servers[to_addr(parts[0]), to_port(parts[1])];
    }

    return new_value;
}

## This manages our broker subscription
function update_uuid(ID: string, new_value: string): string
{
    local cur_value: string = lookup_ID(ID);
    
    // If we already have a UUID, unpublish everything first.
    if ( cur_value != "" )
    {
        local cur_topic = cat("/ezeekonfigurator/control/", cur_value);

        Broker::auto_unpublish(cur_topic, heartbeat);
        Broker::auto_unpublish(cur_topic, last_gasp);
        Broker::auto_unpublish(cur_topic, option_change_reply);
        Broker::auto_unpublish(cur_topic, sensor_info_reply);
        Broker::auto_unpublish(cur_topic, option_list_reply);
        Broker::unsubscribe(cur_topic);
    }

    local new_topic = cat("/ezeekonfigurator/control/", new_value);

    Broker::subscribe(new_topic);
    Broker::auto_publish(new_topic, heartbeat);
    Broker::auto_publish(new_topic, last_gasp);
    Broker::auto_publish(new_topic, option_change_reply);
    Broker::auto_publish(new_topic, sensor_info_reply);
    Broker::auto_publish(new_topic, option_list_reply);

    return new_value;
}

redef Config::config_files += { cat(@DIR, "/conf.dat") };

event zeek_init()
{
    Option::set_change_handler("eZeeKonfigurator::brokerd_peer", update_brokerd_peer);
    Option::set_change_handler("eZeeKonfigurator::uuid", update_uuid);

    for (opt_name, opt_data in global_ids())
        if ( opt_data$option_value )
            Option::set_change_handler(opt_name, change_handler);
}

event Broker::peer_added(endpoint: Broker::EndpointInfo, msg: string) &priority=10
{
    if ( endpoint?$network && [to_addr(endpoint$network$address), endpoint$network$bound_port] in brokerd_servers )
        {
        event eZeeKonfigurator::heartbeat(getpid());
        event eZeeKonfigurator::sensor_info_reply(SensorInfoMessage());
        }
}

event net_done(t: time)
{
    event eZeeKonfigurator::last_gasp("net_done");
}

event zeek_done()
{
    event eZeeKonfigurator::last_gasp("zeek_done");
}

