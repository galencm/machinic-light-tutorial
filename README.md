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

        A button is perhaps the simplest thing, but other basic forms could be very useful such as a variety of sensors (pressure, light, proximity) and inputs (slider, grid). One could imagine a near future where physical things or sensors are 3d printed or computationally fabricated, already containing most necessary circuitry with only minimal modification required. Other protocols are also possible, such as things using zeromq or zyre.

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
    * device configuration or _zooming always or sometimes with ennui_

        slurping simply works, but what if we want the device to be configured in some manner first, such as setting the zoom?

        This has a couple of challenges, devices may or may not preserve state depending on resets or power cycling. Devices may have different ways to be configured. Even within a way of configuration different devices may require different settings, such as the propsets used by chdk-supported cameras.

        Finally this variety should be be structured in a way that allows to be quickly extensible in a way that allows settings to be incrementally added as new devices are tested or settings needed.

        The package enn-ui attempts to solve these concerns:
        * enn-dev: a gui for configured devices that can show connected/disconnected devices, apply and test settings, and specify settings conditionally based on environment variables.
        * enn-env: a basic gui for viewing and modifying environment vars. These vars will likely be modified by other processes or things.
        * `reference.xml`: a file containing a list of devices and configuration methods along with specific calls for configuration methods.
        * enn-db: a commandline program to convert `reference.xml` into lookup values on the database. Commands such as `slurpst` and `slurpif` used these lookups to set state before slurping.

        Before running `enn-dev`, populate the device and script lookup keys:

        ```
        enn-db --db-host 127.0.0.1 --db-port 6379
        ```

        This only needs to be done once for a persistent database or after a modification of `reference.xml`.

        Setting zoom

        start the gui:

        ```
        enn-dev --size=1500x800 -- --db-host 127.0.0.1 --db-port 6379
        ```

        If a device is discovered, various information should be displayed along with a green bar indicated that device is connected. Unplug the device and the bar will turn to gray. Devices are displayed horizontally and stale devices can be cledared by pressing the button at the top of the window.

        **Chdk Note**: some devices may slurp without chdk, but need chdk for settings such as zoom. Chdk can be installed to run automatically when the camera powers on, or can be loaded as a firmware update by menu selection. See various tutorials online.

        **Automount Note**: if a device is not discovered when connected and powered on or is displayed in a file manager, automount may be interfering, see [watch-for-process](https://github.com/galencm/watch-for-process) and note in _Setup and Preparation_.

        At the top of the window we can see that there is a caption "zoom" with an input box beside it. This is generated from the lookup keys. Enter a numerical value(future versions of `reference.xml` should contain minimum, maximum and step values) such as 2 and press enter, the box should glow green. Next press the "set state" button to store in the database. Stored values can be checked by pressing the  "get state" button.

        Press the "preview" button, on some cameras you may hear the zoom setting ... The slurped image will be opened with `dzz-ui`.

        Slurping with these settings can also be done from the commandline:

        **slurpst**: slurp, first looking up and applying any state settings. State settings will always be set without checking any conditions.

        ```
        keli neo-slurpst _ _ --db-host 127.0.0.1 --db-port 6379
        ```

        Setting zoom conditionally

        Press the "new cond" button at lower left of the device information. A form will be created to script conditions and settings.

            * name: a descriptive name, otherwise a uuid will be used
            * _add conditions_(use keyling): specify conditions that must be satisfied to set settings. For example, perhaps a value called width must be between 2 and 5 and another value height between 3 and 8 to set zoom to 2.
            *_add settings_ (use 'foo = bar' per line): settings to set, the "preview" button beneath allows testing of settings.
            * _add post calls_(use keyling): And calls to run post slurp. `slurpif` and `slurpst` supports this.

        One of the goals of conditional scripting is to avoid the need to manually reconfigure the device for repetitive configurations (such as the same height, width, and depth of a book). It also looks forward to a more sensor or input driven way of configuration. For example sensor things providing height, width, and depth values could be routed store those values in the environment var key which is then used to automatically configure devices. Or sensor data could be used to set servos to adjust device position or some other modifying configuration.

        Keyling is a dsl initially created for `fold-ui` and then used in `dzz-ui`, it is designed for working with data in a dictionary form such as found in a redis hash key that is passed in as the sort of context for the keyling script. The [machinic-keli](https://github.com/galencm/machinic-keli) package provides calls that are structured for keyling calls, often accepting the key address and field as parameters with the command then handling the lookup from the database and desired modifications.

        Keyling will be covered more with fold-ui, but roughly a set of statements are in paranthesis, with a comma after each. Statements are evaluated sequentially, with the first false causing the entire statement to return as failure. All conditions must evaluate as true for a success result. A few simple examples:

        ```
        ([bar],) #if field bar exists evaluate as true (success!)

        ([bar]!,) #if field bar does not exist evaluate as true (success!)

        ([bar] > 5,) #if contents of field bar greater than int(5) evaluate as true (success!)
        ```

        so for example a book might involve with the environment var dictionary/hash used as context for _width_, _height_, and _depth_ values.

        ```
        (
        [width] > 5,
        [width] < 7,
        [height] > 5,
        [height] < 7,
        [depth] > 5,
        [depth] < 7,
        )
        ```

        and if success set `zoom = 4`. As you can see the syntax is somewhat clumsy, with a need for a few more operators and support for other types such as comparing floats.

        There is also a pane for _post calls_ which is keyling that is run, for example a call to rotate a slurped image.

        Choose a name and press the "store" button, all panes should glow green to indicate valid syntax. If a pane glows red, it contains a syntactical error and has not been stored.

        Testing a conditional with `enn-env`:

        enn-env displays, creates and updates stored environment variables which are basically a redis hash key following a naming convention machinic:env:<db host>:<db port>. It is a minimal gui. The expectation is that these env vars will be created and modified by various things (such as sensing things), programs and processes as needed.

        ```
        enn-env -- --db-host 127.0.0.1 --db-port 6379
        ```

        Using the _create field_ and _field value_ inputs set "width"  to 6 , "height" to 6, and "depth" to 6. Try using `slurpif` from the commandline and then try setting "depth" to 10 and running `slurpif` again.

        **slurpif**: lookup and evaluate conditions, only if conditions are satisfied, set settings and slurp

        ```
        keli neo-slurpif _ _ --db-host 127.0.0.1 --db-port 6379
        ```

    * realtime visualization and just-in-time structure tailoring

        With reliable slurping and storing of glworbs(or items), focus and concerns can shift to other areas. Such as:
            * are all needed items in the db
            * if there is a structure (such as the page of a book), is there enough information to assemble items to match this structure or tools to do so.
            * how to observe the overall progress of of items or structure from a few hundred to perhaps a few thousand
            * how to specify and highlight problematic conditions in a way that can be easily zoomed in on and corrected
            * how to easily make changes to a single item or replicate across a set of items
            * realtime visualization of the db and any user specified aspects to accurately reflect th state of the work-in-progress

        Two guis `fold-ui` and `dzz-ui` exist to address these concerns. Together they try to make getting(and making) a sense of the project state that is simple to see and easy to modify or adjust.

            * **Fold-ui**: High level, realtime visualization of items and color coding according to user defined specifications. Plugins and views allow for further interactions such as displaying images, editing db values or writing keyling scripts. Fold-ui should provide a sense of of the state of the work-in-progress from database empty of items, to a satisfactory collection that can be exported, archived or outputted to another toolchain.
            * **Dzz-ui**: Mid level, interact with single items to define structural characteristics to be broadly applied. For example: specifying regions to be ocrd and a rule to handle the result if it is an integer (or between a range of integers). Dzz-ui's are imagined to work sort of like pop-ups with the gui opened and closed as needed to specify or modify and updating current state across open windows. Dzz-ui should be useful before, during and after items are slurped. Narrow in functionality, `dzz-ui` may be useful to other programs or processes, such as `enn-dev` which uses it to display slurped images.

        We will start by learning how fold-ui approaches displaying database items and then using to dzz-ui to define some or notate some important elements of our project that fold-ui can then display.

        Running fold-ui:

        ```
        $ fold-ui --size=1500x800 -- --db-port 6379 --db-host 127.0.0.1
        ```

        The larger the monitor the better for fold-ui, it appears as a set of tabs:
            * specify: create specifications that are used to classify cells. Create palettes for specification color-coding.
            * overview: a view of all cells, classified, arranged and color-coded according to specifications
            * folds: a closer view on a subset of columns from the overview. Columns can be unfolded to display contents using various views/plugins.
            * views: Configure view plugins that are used in the folds tab
            * hooks: Events that can have keyling script added and will be run.
            * bindings: keyboard shortcuts, also serves as sort of a documentation of some functionality.

        We can get an immediate sense of how this might work by generating a large amount of items and playing around with the interface. Fold-ui includes a commandline tool to do this called `fairytale` which can be combined with other tools that generate sample images. If we do not want this material to interfere with with our current project we can start a redis-server (with keyspace notifications in config) on a different port, perhaps 7379 and in a different directory(otherwise existing dump.rdb will be used). This is part of the light approach to treat databases as central but also lightweight.

        So let's generate a 90 item boook! To show off some aspects of fold-ui, our boook will be incomplete, it is missing a few items.

        We will do this all in the `/tmp` directory since it is only a prototype to test fold-ui behavior. Adapted from the fold-ui README:

        ```
        $ cd /tmp
        $ printf "notify-keyspace-events KEA\nSAVE 60 1\n" >> redis.conf
        $ redis-server redis.conf --port 7379 &

        $ primitives-generate-boook --title boook --section foo 30 full --section bar 30 full --section baz 30 full --manifest csv --verbose

        $ fold-ui-fairytale --ingest-manifest boook.csv --ingest-map filename binary_key --ingest-as-binary filename --structure-missing 10 --db-del-pattern "glworb:*" --db-port 7379
        ```

        Notice the `--structure-missing 10` parameter when calling `fold-ui-fairytale`. Fairytale has a variety of parameters for structuring and destructing material it creates or adds. To see all parameters run `fold-ui-fairytale -h`.

        Later if we want to stop the redis server, we can do so with the command:

        ```
        redis-cli -p 7379 shutdown
        ```

        We should start fold-ui:

        ```
        $ fold-ui --size=1500x800 -- --db-port 7379 --db-host 127.0.0.1
        ```

        When fold-ui first stars if we click on the overview tab we should see a rectangular grid of gray boxes. These are items in the database that do no match any specification (referred to as a spec). Try setting _column_slots_ to 10 and pressing enter, try clicking somewhere on the boxes. Clicking on the boxes will move the interface to the _folds_ tab with those columns in a horizontal accordion. Nothing is visible so we need to create a spec.

        Creating a spec assumes that we have some sense of the structure that we want our items to be in. There are other tools for exploring redis keys, the simplest being `redis-cli` and fold-ui includes only a basic sampling of items fields and values in the _views_ tab.

        For example we might have a set of items that roughly look like:
            * binary_key: key of a slurped binary blob
            * created: timestamp

        Perhaps more keys are added as we sketch out more of the structure such as a _page_number_ field for any regions that ocr to an integer or a _chapter_ field that is filled out according to a rule that checks for _page_number_ field between certain values and fills in _chapter_ field correctly.

        There may also be additional metadata fields such as device settings used to slurp or working fields used for ocr values. Metadata may also be included at slurp such as some sort of increment or counter to allow sorting by other sequences.

        Depending on the structure we are working with (or working towards) different approaches may make sense:
        * a book, which already contains a great deal of useful structural information as a collection of sections. Each section can be specced and given an expected (rough, there may be more or less) amount of items. Perhaps these sections map to chapters along with bindings and other nonchapter material. This sectioning makes it easy to see where items are missing or duplicated in a more granular way than just _10 missing pages from 90 expected_.
        * other more clever or crude approaches to be developed and shared. Depending on how standard or nonstandard the material is, it seems like there is a lot of potential for optimization or exploration.

        A spec defines the visual aspect of a grid box with regions color-coded based on the presence of various item fields. These fields are given a color(the default color that applies to any field value) and colors can be defined for specific field values (for example: the field part is purple, with red for a value of part1, blue for part2, green for part3). Colors are defined with palette things.

        Regions in a spec can also be toggled to have different properties:
        * primary: a field that all items must have.
        * sortby: sort items by this field
        * continuous: the values of this field should be continuous(incrementing one by one) if not a texture of horizontal bars will be overlaid on discontinuous boxes
        * overlay: for fields containing a key to a binary blob. Overlays an resized image on the box. Useful for seeing that all images are rotated or present.

        Palette thing. The palette thing defines default and value-specific colors along with optional amounts.
        * autogen (checkbox): if checked automatically add name and color for found values of field.
        * sequence:
        * color: select color, graphics will update on any change
        * field name: name to map color to spec
        * value names: specific-value names
            * color
            * expected amount
            * subsequence: not yet implemented

        Specs and palette things can be created and modified as needed. First we can click the "create spec" button on the bottom left pane of the _specify_ tab. We can see a box or cell preview that shows three of the same in vertical row to give a sense of how it will look tiled. The region names are followed by inputs to enter field names and further right, checkboxes to toggle aspects for the field. In the _center_ input enter "section", this will be our primary key.

        Notice that there is still no color, to add a color we need a palette thing. Click on the "create palette thing" button in the lower right corner. A widget will be created with a random color and random name. Try changing the name to "section". Check out the _folds_ tab

        What about specific sections since we know that foo, bar, and baz make up most of our boook? They can be added in the palette thing widget next to the name. Check out the _folds_ tab again. the cells should be multi-colored.

        The colors seem fairly scattered. Try clicking the _sortby_ checkbox for the center region. This will sort by those values.

        Now we are ready to see what is missing. We will add a field without adding a a palette since it will have many integer values, but we want to see if it is continutous. So set the _top_ region to "sequence" and check the **sortby** and **continuous** checkboxes. Since we have specified these values as continuous, discontinuous cells will be given a.n overlay texture of horizontal bars. Check out the _overview_ tab and click on a discontinous cell.

        In the _folds_ tab, each fold shows vertically the cells contained(a grey cell is an empty placeholder) and opening one will show a view of those items. Views(called ViewViewers in the code) are intended to be a modular way of modifying different aspects of the item. The default view, called edit displays a list of of the key:value or field:value pairs that make up the item, these can be modified and written to the db, highlighted for as an environment var(with the _$_), deleted(with the _X_). Some fields are in capitals and begin with _META__, these are fields not from the database but used internally by fold-ui, such as storing the name of the key or any time-to-live (expiration) values. Press tab to cycle through the available views.

        Views can be configured in the _views_ tab, what if we would like to see the images that have been slurped? On the left pane of the _views_ tab we can click on _ImageViewViewerConfig_ and select the field that we know contains an address of a binary blob. If we don't know the field, the right pane might offer some help. For a small number of items, the value of each field is loaded with all available ViewViewers and the result is displayed, if a field contains an reference to an image it should be visible. In this case by scrolling down, we can see that it is _binary_key_. So set the _source key_ input to _binary_key_, return the _folds_ tab and try tabbing through the views.

        The default size of the views is a little wonky, ideally legibility of text would be preserved down to very small sizes and textboxes would scale correctly. In spite of these usability issues, fold-ui has a few default hotkeys for views that can be useful:
        * Ctrl+up: scale items larger, very large items can be scrolled around by clicking anddragging.
        * Ctrl+down: scale items smaller
        * Ctrl+left: increase rows of items (rows increase until items are displayed as a single column)
        * Ctrl+right: decrease rows of items (rows decrease until items are displayed as a single row)

        This gives some flexibility in viewing, want to see images in two columns as thumbnails and then zoom in? Ctrl-left a few times and then Ctrl-up/down as needed. Scripting textbox too small? Increase the scale until it's usable.

        Most settings or configuration made within fold-ui should persist from session to session, settings are stored and loaded from `~/.config/fold/session.xml`.

        **Discontinuities, displaying and correcting**

        Looking at the folds we can see discontinuous regions, but how large is the discontinuity? It could be 1 item or 5 items. A way to to see the missing items more exactly is to specify an expected or rough amount in the palette thing for a named-value and then to check the **sparse_found** checkbox in the _overview_ tab. Now missing values should be indicated by a grey cell, these placeholding cells are visible but will have no associated views in a fold.

        With a sense of what is missing we can try to fill in the blanks, this example is a little contrived since we are working off generated material, but should give a sense of how the gui responds:
        * using `fairytale`:

            use `less -N boook.csv` to display files with line numbers, and ingest the missing items according to the sequence number. For example the call below ingests lines 5 and 6:

            ```
            fold-ui-fairytale --ingest-manifest boook.csv --ingest-map filename binary_key --ingest-manifest-lines 5 6 --ingest-as-binary filename --db-port 7379
            ```

        * using EmptyViewViewer (not yet implemented):

            Useful if slurping using a camera or other device. Run a keyling script to slurp and attach missing metadata to "fill in" the missing cell. Responding to the database events, fold-ui will update.

        ** Exporting **

        If everything looks good we might want to export the images as files. To do this we will run a keyling script on all of the items that given the key address and field name will lookup the field value as a key and dump the bytes as a file. To specify the field to use we will use the highlight button in the edit view. The highlight button is the dollar sign (**$**) beside each row in the edit view. When clicked, the highlight button sets the environment variable **$SELECTED_KEY** which we can then use in our dumping script. The other environment variables we will need are **[*]** or **$SOURCEKEY**, **$DB_PORT** and **$DB_HOST**.

        ```
        ($(<"keli src-artifact $SOURCEKEY $SELECTED_KEY --filename tutorial_$sequence.jpg --path /tmp --db-host $DB_HOST --db-port $DB_PORT">),)
        ```

        Notice that the keyling script above also includes $sequence in lowercase, values of an items field can be substituted by prefacing the field name with a $. So $sequence will attempt substitute with the value of the sequence field (if it exists).

        To run the script we will use the _Script View_ which validates and runs a keyling script on a single cell or all cells. The script can also be stored in the gui by entering an name in the _aliased name_ input and pressing the **add to aliased** button. A button with the name will then be visible in the script view, pressing this button will copy the contents into the script window but not run it, one of the _run script_ buttons must still be pressed.

        Press the **run script on all** button and run `ls -haltr` in the `/tmp` directory. Images named something like `tutorial_35.jpg` should be appearing.

        **Domain Specific Structure**

        When we do not have the luxury of generated material with prestructured metadata, we may have to create our own structurings. Dzz-ui can help with this. Dzz-ui is an interface that combines:
        * selection of rectangles on an image
        * ocring of selected rectangles
        * a simplified interface to generating ruling scripts
        * generation of keyling scripts that can then be copied and pasted into fold-ui or run across all fold-ui keys from dzz-ui

        The general idea behind the rectangle selection, ocring, and ruling rules is that something like a book already contains much useful structure. Page numbers often appear in consistent places, roman numerals may indicate an introduction, chapter names may be on every other page in the top center and so on. Dzz-ui allows one to specify an generality(called a regionpage in dzz-ui, not a reference to a book page) such as _page_numbers_, select regions where they are found(using images) such as bottom left and bottom right, and then define a rule that says if either of these rectangles contains an integer then set the page_number field to that value. Dzz-ui then generates the necessary scripts, shell calls using keli to crop the regions from the image, calls to tessarct to ocr the regions and store the result in the glworb, calls to run the ruling script and write any fields and values if a rule applies.

        These generated scripts that tie together the calls can then be run immediately, pasted into a shell script or added to the fold-ui on_add hook to be run when items are added to the database. Notice that many of the keyling shell calls use the prefix _$$(_ instead of _$(_ that has been used earlier, this indicates a blocking call since calls must occur in a sequence.

        We can call dzz-ui from the commandline, but it would be much better to simply call it from fold-ui where we can see all the images. To do this we can add a keyling script that calls dzz-ui with the correct environment vars and add it as an aliased script.

        In fold-ui copy the following script in the script view:

        ```
        ($(<"dzz-ui --size=1500x800 -- --db-key $SOURCEKEY --db-key-field $SELECTED_KEY --db-host $DB_HOST --db-port $DB_PORT">),)
        ```

        As you can see, it is pretty similar to the export script passing the $SOURCEKEY and $SELECTED_KEY. Add it as an aliased script by entering a name such as dzz in the aliased name input and clicking _add to aliased_. Now to open dzz with the selected key as an image, you can click the _dzz_ button and then click _run script on this_.

        **using dzz-ui to add page numbers**

        If a a boook does not already exist, we can create one using `./example_boook.sh` and use fold-ui as configued above to call dzz-ui. The generated boook already includes a _page_number_ field, but we will ocr the actual image page numbers, check if the ocr result is an integer, and if so, use that result to fill in a field we specify.

        An intitial issue when ocring is that page numbers may appear in different parts of a page, top, bottom, left or right, perhaps alternating or different for a new chapter. We will use fold-ui to find images with different positions of page numbers, open each with dzz-ui and draw regions around the page numbers. Dzz-ui is designed to share data with other open windows, so open as many as needed. A boook has three positions for page numbers, lower left, lower right and lower center if it is a new page. Some pages are not numbered, but we should be able to get page numbers for most.

        Dzz-ui uses something called a regionpage which is a collection of regions(or rectangles) that are stored as geometry and are drawn over an image. These regions can then be used to crop rectangles, ocr the crops, and run ruling scripts on the the ocr results. A regionpage is imagined to contain a sort of concept or structural element such as page_numbers or chapter_headings, each with different regions and rulings.

        First we will make a page_nums regionpage by entering "page_nums" in the large textinput in the upper right corner of a dzz-ui window. Next in the same window click at one corner of the page number and then the opposite corner to create a box, a small dot should appear to indicate each click and once a rectangle is drawn there will be a slight lag as the cropping and ocring occurs.

        A bunch of things happen!

        * Notice also that the rectangle appears in the other open windows!
        * A couple new fields are now visible in the field:value pane:
            * page_nums_key: containing the crop bytes blob
            * page_nums_ocr: the result of running tesseract on the blob
        * The region is automatically given a name(based on area of image) and color(random) and is visible in the upper right pane.
        * Some keyling is generated, this contains all the shell calls for cropping, ocring and ruling. It runs automatically if the _auto run generated scripts_ checkbox is checked.

        The page_nums_ocr field shows that ocring was successful(in this case it was 62), but what about cases where the left and the right are ocrd? If ocring returns an empty result, it will not clobber an existing value, so assuming that only one of the three positions will have a page number, a page number should always be found in the page_nus_ocr(fan-in), further we may wish to only allow integers for page numbers and ignore bad ocrs or other characters. We can do this using ruling which is accessible in dzz-ui in the upper right pane beside the list of regions.

        Ruling grammar is is more capable, but dzz-ui offers a simplified interface for basic things. We click on the **int** button which turns green indicating that is enabled. Beside it are two input boxes the first of which is a field name and the second the field value. We can fill in the first box with "pagenum" and the second with $page_nums_ocr. By prefixing the _$_ we can attempt to substitute the field's value, which in this case must exist if the rule was applied. What we have done is used the interface to create a rule that says if the value of of the regionpage's ocr result can be an integer then set/create the field _pagenum_ with the value of the ocr field. Other rules may be useful, such as checking for any nonempty string, an exact string, a range between integers(for exmple: integers between 1 and 10 set chapter to chapter1) and perhaps other uses.

        Press "regenerate scripts" and the "run script on this", there should be slight lag while the shell calls run and hopefully a new field _pagenum_ with a numerical value will appear.

        This script can then be copied and pasted into fold-ui or run on all the items in fold-ui by clicking the "run script on all" button. Fold-ui stores a key containing a list of all its currently sequenced items, so the button will retrieve this list and run the keyling script on each.
