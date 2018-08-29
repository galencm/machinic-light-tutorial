# Machinic Light Tutorial

_a tutorial to create a book scanner (or system to slurp and sequence images) using machinic_

* General Introduction
    * concepts

        Machinic light is a collection of graphical user interfaces, commandline interfaces, domain specific languages, code generation tools and database conventions. _Light_ refers to an initially more limited scope around slurping and sequencing images and the use of a database host and ip as a way of connecting or isolating various components often seen as the `--db-host` and `--db-port` parameters to all programs.

        Machinic heavy came first and was originally just machinic. It shares concepts and packages with machinic light but differs with a service or microservice (using zerorpc) approach driven by code generation from xml models called machines. _Heavy_ refers to the increased layers or moving pieces that come with the more abstract approach and commandline-centric tooling. Even with service discovery and the leverage that code generation provides, machinic heavy felt excessive for a single user to easily learn and quickly use.

        The light/heavy labels provide a currently informative distinction of structure, but may disappear or change if machinic is useful enough to accrete modifications.

        The machinic ecosystem or machinic then roughly is: 
        * a general collection of programs and packages(clis, guis, dsls)
        * a set of problem solving approaches such as using code generation(inspired by the zeromq projects), defining dsls to provide a refinable notation to concepts that spans tools
        * a philosophy of creating systems that allow things to be done very simply while also offering layers that allow modifications in a flexible and durable manner. For example, creating a basic button should be (and is) very simple using code generation. The generated code can then be further modified, regenerated and put under version control as needed. Or using redis as the underlying db and mosquitto as a broker, since both have much existing tooling and provide a simple way for novel approaches to access and interact with a light system.
        * machinic dogfooding to hopefully allow an ongoing movement of focus and attention towards novel and salient problems/approaches by solving or making frictionless existing problems and stumbling blocks to rapid and easy prototyping and modification. 
* Setup and Preparation
    * programs are needed such as redis-server and chdkptp
    * libraries are needed such as libgphoto2 for using digital cameras
    * see a full list in [environment.xml](https://github.com/galencm/machinic-meta-install/blob/master/environment.xml) which generates install scripts for various linux flavours
    * install everything for machinic light with [machinic-meta-install](https://github.com/galencm/machinic-meta-install):
        ```
        git clone https://github.com/galencm/machinic-meta-install
        cd machinic-meta-install
        ./install-light.sh
        ```

    * **Automount Note**: window manager automounting can interfere with connecting to or using digital cameras. I have created a simple package that addresses this by stopping any automount processes. [watch-for-process](https://github.com/galencm/watch-for-process)  which can be run as a script or installed as a system service(`install_as_service.sh`):

    ```
    $ git clone https://github.com/galencm/watch-for-process
    $ cd watch-for-process/
    $ sudo ./watch_for_process.py gpho
    ```

* The Slurp and Sequence System (SAUCY)
    * a sketch

        Roughly we can imagine our book scanner or SAUCY as an flexible assemblage of hardware and software that allows for the slurping of bytes from camera hardware using some sort of button or trigger and tools/guis to assess and modify the slurped items according to some desired structure. Ideally this should be robust, easily changeable or modifiable and simple to setup.

        For this tutorial SAUCY will use a button routed to a shell call that will slurp from two cameras. Even this diagram may have several permutations, for instance: a gui button and two chdk cameras or a hardware button and two webcams. To allow this permutations: code generation will make different button things simple, messaging and routing will allow different triggers to make the same actions and the slurp call can handle different hardware.
    * generate things and routes

        First we will generate the button code for either a hardware or gui button. To do this we will use `tangle-things`

        ```
        $ cd /tmp
        $ tangle-things button --model-type kivy --name ezpz
        found template: gui_kivy_button.gsl
        GSL/4.1.4 Copyright (c) 1996-2016 iMatix Corporation
                      GSL Developers 2016-2017
        gsl/4 I: Processing model_button.xml...


        GSL/4.1.4 Copyright (c) 1996-2016 iMatix Corporation
                      GSL Developers 2016-2017
        gsl/4 I: Processing model_button.xml...


        to modify code generation, edit .gsl or .xml files and run regenerate.sh
        $ cd button/ez_pz
        $  ls -R ./button_ezpz
        ./button_ezpz:
        ezpz_button  gui_kivy_button.gsl  model_button.xml  regenerate.sh

        ./button_ezpz/ezpz_button:
        button_ezpz.py
        ```

        One can see that using gsl and an xml model `tangle-things` has generated a python file with kivy button and included the xml model, the gsl template and a shell script to easily regenerate the code. While the files and nested directories may be different (for example the homie button thing has more directories to handle platformio), the top level .xml/.gsl/.sh tools will always be generated.

        We can try the button now:
        ```
        $ cd button_ezpz/
        $ python3 ezpz_button/button_ezpz.py
        ```
        But when we press it, iit will likely fail since we have not given it any broker arguments. Start mosquitto if a server is not available.

        ```
        $ mosquitto &
        $ python3 ezpz_button/button_ezpz.py -- --broker-host 127.0.0.1 --broker-port 1883
        ```

        In the terminal you should see something like:
        ```
        /ezpz 1
        /ezpz 1
        /ezpz 1
        ```

        It works! A message "1" is sent on topic/channel "/ezpz"

        We can use to do our routes, but what if we want to send the message on a different channel or change the message?

        We could edit the `button_ezpz.py` code directly, it is a simple enough modification, but this is a useful point to get a better sense of code generation (a longer introduction and documentation can be found on the [gsl](https://github.com/zeromq/gsl) page. It is worth reading).

        In `./button_ezpz` there are three files:
        * model_button.xml

            The xml model used providing a structure to be used by the gsl template. We will edit this to change the channel.
        * gui_kivy_button.gsl

            The gsl template used to output files, directories and other outputs.
        * regenerate.sh

            A simple shell script that calls gsl with the model and template as parameters.

        We could also put these files under version control:

        ```
        $ git init .
        Initialized empty Git repository in /tmp/button_ezpz/.git/
        $ git add .
        $ git commit -m "Problem: no version control
        >
        > Solution: use git
        ```

        Here we follow the zeromq approach of including generated/regenerated code in version control.

        ```
        $ nano model_button.xml
        ```

        and change the channel atttibute:

        ```
        <output value="1" channel="/ezpz"/>
        ```

        to some other name

        ```
        <output value="1" channel="/slurp"/>
        ```

        Now we need to regenerate the code:

        ```
        $ ./regenerate.sh
        ```

        We can see what changed using git:

        ```
        $ git diff
        ```

        Now that we know how to create and modify things say we wanted a hardware button instead of a gui button. A hardware button has certain advantages: easily relocatable in space (especially if using a battery and wifi), no issues of window focus or space that a gui button requires, ever-cheaper chips with wifi and powerful software frameworks.

        Wire up a huzzah esp8266, some buttons and connect it the computer, then use platformio to get dependencies, compile and upload the code:

        ```
        $ tangle-things button --model-type homie --name ezpz3d
        $ cd button_ezpz3d/ezpz3d_button/
        $ platformio run
        $ platformio run -t upload
        ```

        while the thing is connected via usb we can observe it with screen (assuminfg thing is connected to /dev/USB0):

        ```
        $ screen screen /dev/ttyUSB0 115200
        ```

        Note: the photo and code includes two buttons, one button is wired to standard pin (17) and used to reset homie to unconfigured more so that it can be discovered and connected. All homie things (inputs, sensors, etc)will have a reset button.
    * Extending things or _A thousand and one things_

        A button is perhaps the simplest thing, but other basic forms could be very useful such as a variety of sensors (pressure, light, proximity) and inputs (slider, grid). One could imagine a near future where physical things or sensors are 3d printed or computationally fabricated, already containing most necessary circuitry with only minimal modification required.

        Thing models are in the `machinic-tangle` package following a naming scheme of model_<thing_type>.xml

        ```
        model_button.xml
        ```

        Thing templates are in the machinic-tangle package and follow a naming scheme of <general category>_<model type>_<thing type>.gsl.

        ```
        iot_homie_button.gsl
        gui_kivy_button.gsl
        ```

        New things and outputs can be supported by adding models or templates to the package.
    * Creating routes or _taking things places_

        Now that we have a button thing(or button things) we need a way so that the message sent by the button press results in slurping from connected cameras. This is done by creating a route that matches channel messages and actions along with a bridge that subscribes to all broker messages, parses them according to available routes and then handles any route actions, such as writing a value to the database or triggering a shell call.

        Machinic-tangle uses a a domain specific langage(dsl) called pathling to describe routes. It is worth going into a little detail on dsls since they are used in other parts of machinic. Machinic uses dsls(usually called lings) as a way of providing a narrow notation for an area of the system while preserving programmatic flexibility and hopefully ease of use. The python package [textx](https://github.com/igordejanovic/textX) makes definition and creation of dsls and parsing code straightforward. The downside of using dsls in this way is that a variety of syntaxes must be learned along with friction that the dsl adds. Lings in machinic are a work in progress and seem to be useful as way of adding scripting to guis while also be insertable as strings into the database, hopefully dogfooding will give some insight into the approach.

        Some lings in machinic. Bolded lings will be discussed in this tutorial:
        * **Pathling**: used by light for routing. [grammar](https://github.com/galencm/machinic-tangle/blob/master/machinic_tangle/pathling.tx)
        * **Keyling**: used by `fold-ui` and `dzz-ui` for modifying items(glworbs) in the database. Used by `enn-dev` and `neo-slurpif` to conditionally slurp. [grammar](https://github.com/galencm/fold-lattice-ui/blob/master/fold_ui/keyling.tx)
        * **Ruling**: used by light and heavy. Evaluate and apply rules. Used by `dzz-ui` to create rules for ocr regions. [grammar](https://github.com/galencm/machinic-lings/blob/master/lings/ruling.tx)
        * Routeling: used by heavy for routing, precursor to pathling. [grammar](https://github.com/galencm/machinic-lings/blob/master/lings/routeling.tx)
        * Pipeling: used by heavy for structuring sequences of calls. [grammar](https://github.com/galencm/machinic-lings/blob/master/lings/pipeling.tx)

        We will use `tangle-ui` to create the routes. `tangle-ui` combines a variety of processes into a single user interface. It handles:
        * running a broker (mosquitto)
        * running a bridge connected to broker and db
        * running a wifi scan process that looks for unconfigured things and configures them
        * running a wifi access point for configured things to connect to
        and provides:
        * a window to create/update routes using pathling
        * a window showing broker messages
        * a window showing db messages
        * a window showing discovered ssids
        * a window showing connections to access point

        Routes can also be created as strings written directly to the db with a standalone bridge process running.

        Assuming that a redis-server is already running somewhere. Start `tangle-ui` with the `--allow-shell-calls` flag to allow pathling to make shell calls:

        ```
        $  tangle-ui --size=1500x800 -- --db-port 6379 --db-host 127.0.0.1 --allow-shell-calls
        ```

        There will be a sudo prompt in the terminal for wireless scanning and access point creation subprocess calls. Tangle ui can also be run with sudo:

        ```
        $ sudo $(tangle-ui --size=1500x800 -- --db-port 6379 --db-host 127.0.0.1 --allow-shell-calls)
        ```

        The first view of tangle-ui is confusing since it tries to show all the views needed to determine that things are successfully discovered, configured, connected and routing. Don't worry most of it should be automatic and all we have to do is add a route.

        In the routes pane in the upper left corner add the following pathling line:

        ```
        /slurp -- $(keli neo-slurp _ _ --db-host $DB_HOST --db-port $DB_PORT)
        ```

        A pathling line can be divided roughly into three parts `/slurp` which is the channel, `--` which is the action symbol and the destination, in this case a shell call: `$(..)`. Several lings use the idea of environment vars to allow more flexible scripting. Here we can see $DB_HOST and $DB_PORT passed which will be supplied by tangle ui in a dictionary and correctly replaced when the pathling shell call is about to be run. The underscores after neo-slurp are just placeholder arguments and an artifact of neoslurp. To see more keli commands, run `keli list` on the commandline or look at the [machinic-keli](https://github.com/galencm/machinic-keli) package

        and press the update routes button. The pane should flash and a message will appear in the redis pane showing that the route has been written to the database.

        To remove a route, prefix it with a dash "-" and press the update routes button.

        If one tries to add route that has incorrect syntax, the pane will comment out the route by prefixing it with '#' and display the parsing message as a comment beneath the route. For example:

        Note the extra '-', '---' instead of '--':

        ```
        /slurp --- $(keli neo-slurp _ _ --db-host $DB_HOST --db-port $DB_PORT)
        ```
        which results in the following:

        ```
        #/slurp --- $(keli neo-slurp _ _ --db-host $DB_HOST --db-port $DB_PORT)
        #Expected'(\w+)' or STRING or '$$(' or '$(' at position(1, 10) => '/slurp --*- $(keli n'.
        ```

        The asterix displays where there problem occurs and the message helpfully prints what is expected based on the grammar. To see the pathling grammar see `pathling.tx` and example string in `pathling_spec.txt`, both in the machinic-tangle package.

        Once the route has been added, we should be able to turn the camera(s) on and press our gui button.

        For the hardware button, two wireless interfaces are needed, one to scan and another to serve as an access point. Tangle-ui tries to start these automatically using _wls1_ for scanning and _wlp0s26f7u1_ for the access point. Not all wireless devices work for creating access points, an Alfa AWUS036NHA works. Hopefully a list of working hardware can be created.

        If it is the first time the hardware thing has been turned on it should be an unconfigured mode, which creates an access point and accepts a json configuration. Otherwise press the the reset button. The thing should appear in the "scanned ssids" as homie-<something>, then once it has been configured, the ap connections pane should display (2 hosts up). The mqtt pane should show the regular homie status messages and when the button is pressed:

        ```
        topic: /slurp contents :1
        ```

        then the camera(s) should click and the redis pane will show keys and bytes being written to the db.


    * refine with device configuration
    * realtime tools
        * fold-ui
        * dzz-ui
    * Modifying, Improving, Extending