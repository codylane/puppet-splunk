# splunk

This module is a refactor/rewrite of a module that used to exist on the
forge. I can no longer find the original maintainer but this work was
inspired by the original author.

If I can find this person I will make sure to mention this persons
original work within this repo.


#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with splunk](#setup)
    * [What splunk affects](#what-splunk-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with splunk](#beginning-with-splunk)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview


The Splunk module manages both Splunk servers and forwarders on RedHat, Debian, and Ubuntu.

## Module Description

The Splunk module manages both Splunk servers and forwarders. It attempts to make
educated and sane guesses at defaults, but requires some explicit configuration via hiera or
passed parameters. Supported OS's include RedHat, Debian, and Ubuntu. Puppet versions
include Puppet 2.7, 3.x, 4.x.

## Setup

### What splunk affects

* Installation of Splunk Packages
* Managment of the service init script (/etc/init.d/splunk)
* Managment of configuration files under /opt/splunk
  * inputs.conf and outputs.conf
  * indexes.conf on indexers and search heads
  * deploymentclient.conf on universal forwarder
* listened-to ports for Heavy forwarders and indexers


### Setup Requirements

If your running a version of Puppet that does not have pluginsync enabled,
it should be enabled.

Use of Hiera for passing parameters is *highly* encouraged!

### Beginning with splunk

Disabled inputs for  sourcetype "lsof" "ps" as they are verbose and create
a lot of events.

By default behavior is to install a Universal Forwarder and configure the
agent to forward events to one or many indexers. The below example will
install and configure a universal forwarder to send events via port to an
indexer at IP 1.2.3.4 listening on port 9997. target_group takes the form
of a hash, with name as the name keyword for your indexer, and the IP as
the value.  So a more real world example might be
{ 'datacenter1' => 'IP/DNS Enter' }

```Puppet
class { 'splunk':
  target_group => { 'name' => '1.2.3.4' },
}
```

To Change the "type" of installation, for example from a Universal forwarder to a
Light Weight Forwarder, you can pass the "type" paramter to the Splunk Class.
It is worth noting that the module will attempt to cleanup after itself.
So for example if your default node definition installs the
universal forwarder, and you place the node into a role that inludes the
light weight forwarder type, the Splunk module will attempt to uninstall
and clean up the universal forwarder from /opt/splunkforwarder before
installing into /opt/splunk. This typically has little effect,
but does cause the newly installed agent to reindex any inputs that
were assigned to both types.

```Puppet
class { 'splunk':
  type         => 'lwf',
  target_group => { 'name' => '1.2.3.4' },
}
```

## Usage

[Classes and Defined Types](#classes-and-defined-types)
  * [Class: Splunk](#class-splunk)
[Splunk Universal Forwarder](#splunk-universal-forwarder)
[Splunk Light Weight Forwarder](#splunk-light-weight-forwarder)
[Splunk Indexer](#splunk-indexer)
[Deployment Client](#configure-deployment-client)
[Inputs.conf](#splunkinputs)
[Outputs.conf](#splunkoutputs)
[Props.conf](#splunkprops)
[Transforms.conf](#splunktransforms)
[Server Ulimit](#splunkulimit)
[limits.conf](#splunklimits)

### Classes and defined types
####Class: `splunk`
##### `configure_outputs`
Toggle to enable/disable managment of the outputs.conf file. You may want
to disable the module managment of outputs.conf if you use a deployment server
to manage that file.  Defaults to true

##### `index`
Default index to sent inputs to. Defaults to 'os'


##### `licenseserver`
fqdn of License host, passing this param will turn the node into a license
slave of a configured license server.
For a license master set licenseserver => 'self'

##### `output_hash`
Optional hash of outputs that can be used instead of, or in addition to the
default group (tcpout) Useful for forwarding data to third party tools from
indexers.

```Puppet
   output_hash   => { 'syslog:example_group' => {
                        'server' => 'server.example.com:514' }
                    }
```

##### `package_provider`
Defaults to undef

##### `package_source`
Defaults to undef

##### `port`
Splunk Default Input Port for indexers. Defaults to 9997. This sets both
The ports Monitored and the ports set in outputs.conf

##### `proxyserver`
Define a proxy server for Splunk to use. Defaults to false.

##### `purge`
```Puppet
purge => true
```

purge defaults to false, and only accepts a boolean as an argument.
purge purges all traces of splunk *without* a backup.

##### `splunkadmin`

##### `target_group`
Hash used to define splunk default groups and servers, valid configs are

```Puppet
{ 'target group name' => 'server/ip' }
```

##### `type`
Install type. Defaults to Universal Forwarder valid inputs are:
 * uf      : Splunk Universal Forwarder
 * lwf     : Splunk Light Weight Forwarder
 * hwf     : Splunk Heavy Weight Forwarder
 * jobs    : Splunk Jobs Server - Search + Forwarding
 * search  : Splunk Search Head
 * indexer : Splunk Distribuited Index Server

##### `version`
Install package version, defaults to 'latest'


### Splunk Universal Forwarder

To Configure a Universal Forwarder that send data to server 1.2.3.4 on port 50514

```Puppet
class { 'splunk':
  port         => '50514',
  target_group => { 'name' => '1.2.3.4' },
}
```

The Below example configures a Universal Forwarder to send data to
an index server at IP 1.2.3.4 and port 50514, but **does not specify any inputs.**

```Puppet
class { 'splunk':
  port         => '50514',
  target_group => { 'name' => '1.2.3.4' },
}
```

### Splunk Light Weight Forwarder

This example configures a Light Weight Forwarder to forward data to index
server splunkindex.example.edu at port 50514, and sets the default index to
"ns-os".

```Puppet
class { 'splunk':
  index        => 'ns-os',
  type         => 'lwf',
  port         => '50514',
  target_group => { 'name' => 'splunkindex.example.edu' },
}
```

### Splunk Indexer

This example creates a Splunk Index Server that forwards data to a third party system over both syslog(udp) and raw tcp. This example configured inputs, props, transforms and outputs as well as installing the UNIX TA. Leaving other options as defaults, or picked up by hiera.

```Puppet
  class { 'splunk':
    type            => 'indexer',
    indexandforward => 'True',
    output_hash => {'syslog:qradar_group' =>
                    { 'server' => 'q.example.edu:514' },
                      'tcpout:qradar_tcp' =>
                        { 'server'         => 'q.example.edu:12468',
                          'sendCookedData' => 'False' }
                  }
  }
  class { 'splunk::inputs':
    input_hash =>  { 'splunktcp://50514' => {} }
  }
  class { 'splunk::props':
    input_hash => {
                    'lsof'                 =>
                      { 'TRANSFORMS-null' => 'setnull' },
                    'ps'                   =>
                      { 'TRANSFORMS-null' => 'setnull' },
                    'linux_secure'         =>
                      { 'TRANSFORMS-nyc'  => 'send_to_qradar' },
                    'WinEventLog:Security' =>
                      { 'TRANSFORMS-nyc'  => 'send_to_qradar_tcp' }
                  }
  }
  class { 'splunk::transforms':
    input_hash => {
                    'setnull'            =>
                      { 'REGEX'    => '.',
                        'DEST_KEY' => 'queue',
                        'FORMAT'   => 'nullQueue' },
                    'send_to_qradar'     =>
                      { 'REGEX'    => '.',
                        'DEST_KEY' => '_SYSLOG_ROUTING',
                        'FORMAT'   => 'qradar_group' },
                    'send_to_qradar_tcp' =>
                      { 'REGEX'    => '.',
                        'DEST_KEY' => '_TCP_ROUTING',
                        'FORMAT'   => 'qradar_tcp' }
                  }
  }
```

#### Configure Deployment Client
If you have a Splunk Deployment Server set up, you can bind the Splunk instance
running on your node to a deployment server with the deploymentclient sub class.
Add this to your node.pp or site/<node type module>. In the below example we are managing
A Light Weight Forwarder with foo.com on port 8089.  Please NOTE - Some basic aspects of
the client are still under Puppet Control.
- Version
- Admin PW
- Type

```Puppet
class { 'splunk':
  type => 'lwf',
}
class { 'splunk::deploymentclient':
  targeturi => 'foo.com:8089',
}
```

### splunk::inputs
  This is an optional sub-class which you can pass a nested hash into to create
  custom inputs for Heavy Fowarders, agents or indexers

  By Default the file is created in $splunkhome/etc/system/local

```Puppet
class { 'splunk::inputs':
  input_hash   => { 'script://./bin/sshdChecker.sh' => {
                       disabled   => 'true',
                       index      => 'os',
                       interval   => '3600',
                       source     => 'Unix:SSHDConfig',
                       sourcetype => 'Unix:SSHDConfig'},
                     'script://./bin/sshdChecker.sh2' => {
                       disabled   => 'true2',
                       index      => 'os2',
                       interval   => '36002',
                       source     => 'Unix:SSHDConfig2',
                       sourcetype => 'Unix:SSHDConfig2'}
                   }

```

### splunk::props
  This is an optional sub-class which you can pass a nested hash into to create
  custom props.conf

  By Default the file is created in $splunkhome/etc/system/local

### splunk::transforms
  This is an optional sub-class which you can pass a nested hash into to create
  custom transforms

  By Default the file is created in $splunkhome/etc/system/local

### splunk::ulimit
  splunk::ulimit takes two parameters, the name of the limit to change
  and the number of files to allow.

 [name]
   Name of the limit to change (instance name).

 [value]
   The value to set for this limit.

```Puppet
  splunk::ulimit { 'nofile':
    value => 16384,
  }
```
### splunk::limits
  This is an optional sub-class which you can pass a nested hash into to create
  custom limits for Heavy Fowarders, agents or indexers

  By Default the file is created in $splunkhome/etc/system/local

```Puppet
class { 'splunk::limits':
  limit_hash  => { 'search' => {
                    max_searches_per_cpu => '1'},
                    'thruput' => {
                      maxKBps   => '10240',}
 }

```

## Limitations

### RHEL/CentOS 5

* RHEL/CentOS 5 supported

### RHEL/CentOS 6

* RHEL/CentOS 6 supported

### RHEL/CentOS 7

* RHEL/CentOS 7 Support has not been added

## Development

Quickstart:

    gem install bundler
    bundle install
    bundle exec rake spec

To run beaker tests:

    bundle exec rake beaker
