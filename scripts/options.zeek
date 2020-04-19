module eZeeKonfigurator;

export {

    ## Upon startup, we tell the server what options are available to be set.
    type OptionInfo: record {

        ## Zeek data type (count, interval, etc.)
        type_name: string;

        ## Current value
        value: any;

        ## The Zeekygen docstring
        doc: string;
    };

    ## A table, indexed by the name of the option, with the info for that option.
    type OptionList: table[string] of OptionInfo;

    ## This calls global_ids and builds our OptionList for IDs that are options.
    global dump_ids: function(): OptionList;

    type OptionListMessage: record {

        ##  The list of options.
        options: OptionList &default=dump_ids();
    };

    ## Some basic info about ourselves.
    type SensorInfoMessage: record {
    
        ## Sensor hostname
        hostname:             string &default=gethostname();

	## Current time
        current_time:         time   &default=current_time();

	## Network time (time of last packet)
        network_time:         time   &default=network_time();

	## Process ID
        pid:                  count  &default=getpid();

	## Are we sniffing an interface?
        reading_live_traffic: bool   &default=reading_live_traffic();

	## Are we reading a PCAP?
        reading_traces:       bool   &default=reading_traces();

	## Zeek version
        zeek_version:         string &default=zeek_version();

    };

}

# Our request/reply events for communication with the broker daemon

# sensor_info will send back a SensorInfoMessage
global sensor_info_reply: event(si: SensorInfoMessage);

# option_list will send back an OptionListMessage
global option_list_reply: event(si: OptionListMessage);

# This is how the server requests we update an option
global option_change_request: event(name: string, val: any);

# ...and then we confirm that we've done so.
global option_change_reply: event(name: string, val: any, result: bool);

# This is how we inform the server that we're shutting down.
global last_gasp: event(msg: string);

# Every minute, we send a heartbeat.
event eZeeKonfigurator::heartbeat(pid: count)
{
    schedule 1 min { eZeeKonfigurator::heartbeat(getpid()) };
}

event eZeeKonfigurator::sensor_info_request(t: time)
{
    event eZeeKonfigurator::sensor_info_reply(SensorInfoMessage());
}

event eZeeKonfigurator::option_list_request(t: time)
{
    event eZeeKonfigurator::option_list_reply(OptionListMessage());
}

function change_handler(ID: string, new_val: any): any
{
    event eZeeKonfigurator::option_change_reply(ID, lookup_ID(ID), new_val);
    return new_val;
}

# This builds a list of the values of all our existing options
function dump_ids(): OptionList
{
    local ids = global_ids();
    local opts = OptionList();
    for (k in ids)
    {
        local v = ids[k];
        if ( v$option_value )
        {
            opts[k] = OptionInfo($type_name=type_name(v$value), $value=v$value, $doc=get_identifier_comments(k));
        }
    }
    return opts;
}

event option_change_request(name: string, val: any)
{
    Config::set_value(name, val);
}

