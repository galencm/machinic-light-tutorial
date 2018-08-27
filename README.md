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
    * install everything for machinic light with [machinic-meta-install](https://github.com/galencm/):
        ```
        git clone https://github.com/galencm/machinic-meta-install
        cd machinic-meta-install
        ./install-light.sh
        ```

* The Slurp and Sequence System
    * a sketch
    * generate things and routes
    * refine with device configuration
    * realtime tools
        * fold-ui
        * dzz-ui
    * Modifying, Improving, Extending