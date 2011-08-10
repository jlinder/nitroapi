Nitro API
============

Client for Bunchball's Nitro API http://www.bunchball.com/nitro/
(not complete)

Usage
--------
First, checkout the examples folder. TL;DR:

* create connection object with your api_key, and secret.

```ruby
require 'nitro_api'
nitro = NitroApi::NitroApi.new user, settings['key'], settings['secret']
```

* login

```ruby
nitro.login
```

* log actions

```ruby
nitro.log_action "Video_Watch"
```

* check status

```ruby
nitro.action_history "Video_Watch"
nitro.challenge_progress :challenge => "Watch 10 Videos"
```

Installing
----------
add to your Gemfile
```
gem 'nitroapi', :git => 'git://github.com/KeasInc/nitroapi.git'
```

Change Log
----------
0.0.5

#### Bug fixes:

* handle empty responses for challenge_progress and action_history

License
-------

Copyright (c) Keas Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

