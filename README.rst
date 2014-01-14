================================
CLI to upload to OpenStack Swift
================================

:Homepage:  https://github.com/chmouel/upcs
:Credits:   Chmouel Boudjnah <chmouel@chmouel.com>
:Licence:   BSD

DESCRIPTION
===========

upcs is a simple bash script that use curl on the back-end to upload files quickly to OpenStack swift (v1 & v2 support).

If the container uploaded is a public container then it will give you the public link for easy sharing.

upcs is the acronym to :

[UP]load to [C]loud [S]wiftly.

REQUIREMENT
===========

- Bash >= 3.0
- curl
- xsel (optional)

Operating Systems
=================

This has been tested and developed on MacOSX and Linux system.

USAGE
======

For the first time running upcs will ask you for your API username and key and which Rackspace data-center to use (us or uk). If connected successfully it will ask you to which container to upload.

Options::

 upcs OPTIONS FILES1 FILE2...

 Use curl on the backend to upload files to rackspace Cloud Files.

 Options are :

 -s - Use Servicenet to upload.
 -u Username - specify an alternate username than the one stored in config
 -k Api_Key - specify an alternate apikey.
 -a Auth_URL - specify an alternate auth server.
 -c Container - specify the container to upload.
 -d - Use the last chosen container to upload.
 -C Content/Type - force a specific a content-type for file(s) uploaded.
 -m Container - create container.
 -z Segment_Size_MB - upload large files in given size segments, in MB (default: 5120 MB)
 -t Delete the object after X seconds (default: never)
 -x - set debug mode.

 Config is inside ~/.config/rackspace-cloud/config.

CNAME
=====

`upcs` has the ability to use a CNAME of your public containers instead of the CDN url.

Let's say you have a CNAME set like this ::

 c000.r00.cf0.rackcdn.com CNAME public.mydomain.com

if you set the container header ::

  X-Container-Meta-Cname: public.mydomain.com

on your container header (see the API documentation for this) it will show you the public.mydomain.com instead of c000.r00.cf0.rackcdn.com for the public url.
  
Configuration and OpenStack-Swift
=================================

If you want to upload to your custom swift installation. You can edit
the variable ``AUTH_SERVER`` in ``~/.config/rackspace-cloud/config``
to your swift install. This file get generated the first time you run
upcs if you specify a URL starting by http:// instead of ```us``` or ```uk``` for
auth server it will use that to get tokens. Same goes if you need to 
update your API key you can easily do that by editing this file.

LICENSE
=======

Unless otherwise noted, all files are released under the `MIT`_ license,
exceptions contain licensing information in them.

.. _`MIT`: http://en.wikipedia.org/wiki/MIT_License

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

  Except as contained in this notice, the name of Rackspace US, Inc. shall not
  be used in advertising or otherwise to promote the sale, use or other dealings
  in this Software without prior written authorization from Rackspace US, Inc. 

Author
======

Chmouel Boudjnah <chmouel@chmouel.com>

Contributor
===========

Rick Harris <rconradharris@gmail.com>
