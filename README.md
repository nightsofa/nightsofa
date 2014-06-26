[![NIGHTSOFA](http://i.imgur.com/rcdZQ34.png)](http://nightsofa.com)


[NightSofa](http://nightsofa.com) is an experiment that uses fully public APIs to find public buckups of Movies and in the future other size-heavy media files. We push JS & HTML5 and creativity to the limits.

We believe in **Design**, simplicity and ease of use. 

You are invited tell us your crazy workaround hacky ideas! This is just starting.


## Contribute

Clone this repo and use grunt to build the app.

````$ grunt default```



## Roadmap

- Refine UI/UX design.
- Mutiple browser supports (currently optimized for chrome)
- Mobile version. (now crashing)
- Much more (look and create new issues)


## How do we do it?

NightSofa does not store any media. In fact we do not store anything. We don't have any persistant storage database of any kind. All the code runs in client-side. We take advantage of masive popular public cloud-services that allow people to store and share their buckups freely. We just find them.


### Tech

- HTML5 + JS/CoffeeScript + CSS/LESS
- **JS Framework**: Backbone.js
- **Video Player**: Video.js


### APIs (v0.0.1)

- **Google Search API**: Find the movie "backup" files
- **Google Drive**: Movie "backup" files storage
- **YTS.re API**: Popular titles catalog
- **Trakt.tv API**: Titles metadata
- **IMDB API**: Search autocomplete
- **WhateverOrigin.org API**: Retrieve Google Drive raw streams



## Versions

We are in the very most *alpha* version. v0.0.1



## Who are you?

Geeks from Uruguay & Argentina. You are hearing a lot from us lately, right? :) 



## License

***Contribute, copy, remix, hack it as much as you wish.***

The MIT License (MIT)

Copyright (c) 2014 NIGHTSOFA

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
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
