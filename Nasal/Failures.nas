    # Change multiplier to get different failure probability, for example:
    # 1 = 100% probability for some system to fail every 10 minutes (with 'interval' set to default 600)
    # 0.167 = 1 malfunction per hour
    # 0.00694 = 1 malfunction per 24 hours
    # 0 = no failures (but script still continues to work)

    var multiplier = 0.167;                 # multiplier to change overall failure probability
    var interval = 1800;                     # interval of failure probability check in seconds 1800
    var onScreenMessages = 1;               # show on-screen messages? 1 = yes, 0 = no

    #-----------------------------------------------------------------------------------------------------------
    # probability for each system and instrument
    # balanced for 100% probability of malfunction in two engine aircraft
    # at first loop pass with multiplier set to 1

    var engineDamProb = 0.09;

    var electricSysDdmProb = 0.0085;
    var pitotSysDamProb = 0.0085;
    var staticSysDamProb = 0.0085;
    var vacuumSysDamProb = 0.0085;

    var airspeedIndDamProb = 0.0084;
    var attitudeIndDamProb = 0.0084;
    var altimeterIndDamProb = 0.0084;
    var turnIndDamProb = 0.0084;
    var slipSkidBallDamProb = 0.0084;
    var headingIndDamProb = 0.0084;
    var verticalSpeedIndDamprob = 0.0084;
    var magneticCompassDamProb = 0.0804;

    var aileronJam = 0.0082;
    var elevatorJam = 0.0082;
    var flapsJam = 0.0082;
    var rudderJam = 0.0082;
    var speedbrakeJam = 0.0082;
    var gearJam = 0.0085;

    #-------------------------------------------------------------------------------------------------------------
    # systems and instruments list [variable name, path to property,system or instrument name]

    sysFailList = [[electricSysDdmProb, "/systems/electrical/serviceable", "ELECTRICAL SYSTEM"],
                   [pitotSysDamProb, "/systems/pitot/serviceable", "PITOT TUBE"],
                   [staticSysDamProb, "/systems/static/serviceable", "PITOT-STATIC SYSTEM"],
                   [vacuumSysDamProb, "/systems/vacuum/serviceable", "VACUUM SYSTEM"],
                   [airspeedIndDamProb, "/instrumentation/airspeed-indicator/serviceable", "AIRSPEED INDICATOR"],
                   [attitudeIndDamProb, "/instrumentation/attitude-indicator/serviceable", "ATTITUDE INDICATOR"],
                   [altimeterIndDamProb, "/instrumentation/altimeter/serviceable", "ALTIMETER"],
                   [turnIndDamProb, "/instrumentation/turn-indicator/serviceable", "TURN INDICATOR"],
                   [slipSkidBallDamProb, "/instrumentation/slip-skid-ball/serviceable", "SLIP/SKID BALL"],
                   [headingIndDamProb, "/instrumentation/heading-indicator/serviceable", "HEADING INDICATOR"],
                   [verticalSpeedIndDamprob, "/instrumentation/vertical-speed-indicator/serviceable", "VERTICAL SPEED INDICATOR"],
                   [magneticCompassDamProb, "/instrumentation/magnetic-compass/serviceable", "MAGNETIC COMPASS"]];

    sysJamList = [[aileronJam, "/controls/flight/aileron", "AILERON"],
                  [elevatorJam, "/controls/flight/elevator", "ELEVATOR"],
                  [flapsJam, "/controls/flight/flaps", "FLAPS"],
                  [rudderJam, "/controls/flight/rudder", "RUDDER"],
                  [speedbrakeJam, "/controls/flight/speedbrake", "SPEEDBRAKE"],
                  [gearJam, "/controls/gear/gear-down", "GEAR"]];

    #----------------------------------------------------------------------------------------------------------------


    var welcomeMessage = func {
       print("Starting Failure Management System");
    }

    var engineOff = func {
        for(i=0; i < 8; i = i+1) {                            # set for up to 8 engines
       var magnetos = props.globals.getNode("/controls/engines/engine["~i~"]/magnetos", 1);
       var condition = props.globals.getNode("/controls/engines/engine["~i~"]/condition", 1);
       var cutoff = props.globals.getNode("/controls/engines/engine["~i~"]/cutoff", 1);
            if(getprop("/engines/engine["~i~"]/running") == 1) {      # ignores not active engines
                if(rand() < engineDamProb * multiplier) {                   # check failure probability
                    magnetos.setValue(0);
                    condition.setValue(0);
                    cutoff.setValue(1);
                    magnetos.setAttribute("writable", 0);         # writable protected
                    condition.setAttribute("writable", 0);
                    cutoff.setAttribute("writable", 0);
                    var gtmTime = getprop("/sim/time/gmt-string");
                    print('AT '~gtmTime~' GMT; ENGINE NUMBER '~(i+1)~' FAILURE HAS OCCURRED!');
                    if(onScreenMessages) {screen.log.write('ENGINE NUMBER '~(i+1)~' FAILURE HAS OCCURRED!');}
                }
            }
        }
    }

    var systemOff = func {
        forindex(i; sysFailList) {
            if(getprop(sysFailList[i][1]) == 1) {                    # ignores already inactive systems
                if(rand() < sysFailList[i][0] * multiplier) {        # check failure probability
                    setprop(sysFailList[i][1], "false");
                    var gtmTime = getprop("/sim/time/gmt-string");
                    print('AT '~gtmTime~' GMT; '~sysFailList[i][2]~' FAILURE HAS OCCURRED!');
                    if(onScreenMessages) {screen.log.write(''~sysFailList[i][2]~' FAILURE HAS OCCURRED!');}
                }
            }
        }
    }

    var sysJam = func {
        forindex(i; sysJamList) {
            var prop = props.globals.getNode(sysJamList[i][1]);
            if(prop.getAttribute("writable") == 1) {                     # ignores already jammed systems
                if(rand() < sysJamList[i][0] * multiplier) {          # check failure probability
                    prop.setAttribute("writable", 0);                    # writable protected
                    var gtmTime = getprop("/sim/time/gmt-string");
                    print('AT '~gtmTime~' GMT; '~sysJamList[i][2]~' FAILURE HAS OCCURRED!');
                    if(onScreenMessages) {screen.log.write(''~sysJamList[i][2]~' FAILURE HAS OCCURRED!');}
                }
            }
        }
    }


    var loop = func {
    #    var gtmTime = getprop("/sim/time/gmt-string");
    #    print('At'~gtmTime~'; systems has been checked for malfunctions');
        engineOff();
        systemOff();
        sysJam();
        settimer(loop, interval);
    }

    settimer(welcomeMessage, 0);
    settimer(loop, 200);                 # wait at start, if not - errors can occur!

    setlistener("/sim/signals/reinit", func {                 # on reset
        var n = getprop("/sim/signals/reinit");
	if ( n != nil )
        #if (n.getValue())                                        # ... (but only at the beginning of it)
            for(i=0; i < 8; i = i+1) {  # set for up to 8 engines
           var magnetos = props.globals.getNode("/controls/engines/engine["~i~"]/magnetos", 1);
           var condition = props.globals.getNode("/controls/engines/engine["~i~"]/condition", 1);
           var cutoff = props.globals.getNode("/controls/engines/engine["~i~"]/cutoff", 1);
                  magnetos.setAttribute("writable", 1);               # ... make the property writable again
                  condition.setAttribute("writable", 1);
                  cutoff.setAttribute("writable", 1);
            }
            forindex(i; sysJamList) 
	    {
                var prop = props.globals.getNode(sysJamList[i][1]);
                prop.setAttribute("writable", 1);
            }
    });