module eZeeKonfigurator;

@load ./options

export {

    ## The brokerd port we connect to
    const brokerd_port: port = 45570/tcp &redef;

    ## The brokerd port we connect to
    const brokerd_address: addr = 127.0.0.1 &redef;

    ## Our unique identifier
    const uuid: string = "" &redef;

    ## URL of our eZeeKonfigurator webserver
    const url: string = "http://localhost:8000/" &redef;

}

function start_brokerd()
{
    local env: table[string] of string = { ["BROKERD_BIND_PORT"] = cat(port_to_count(brokerd_port)),
                                           ["UUID"] = uuid,
                                           ["URL"] = url,
                                         };
    
    system_env("./venv/bin/run_brokerd.py", env);
}

event zeek_init()
{
    start_brokerd();
    Broker::peer(brokerd_address, brokerd_port);
}

event Broker::peer_added(endpoint: Broker::EndpointInfo, msg: string) &priority=10
{
    if ( endpoint?$network && to_addr(endpoint$network$address) == brokerd_address && endpoint$network$bound_port == brokerd_port )
        {
        local topic = cat("/ezeekonfigurator/control/", uuid);

        Broker::subscribe(topic);
        Broker::auto_publish(new_topic, heartbeat);
        Broker::auto_publish(new_topic, last_gasp);
        Broker::auto_publish(new_topic, option_change_reply);
        Broker::auto_publish(new_topic, sensor_info_reply);
        Broker::auto_publish(new_topic, option_list_reply);
            
        event eZeeKonfigurator::heartbeat(getpid());
        event eZeeKonfigurator::sensor_info_reply(SensorInfoMessage());
        }
}

event Broker::peer_lost(endpoint: Broker::EndpointInfo, msg: string) &priority=10
{
    if ( endpoint?$network && to_addr(endpoint$network$address) == brokerd_address && endpoint$network$bound_port == brokerd_port )
        {
        start_brokerd();
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

