---
title: Story and Design
author: Kenny Cason
tags: game design
---

Before getting started on any large project, I reckon it's considered good practice to plan before you build. This doesn't mean you need to write a 100 page detailed design document, nor plan every single micro detail of the game. However, defining the basic story, game style, a few enemies, weapons, items, etc, is a good way to get a feel for the kind of game you want to develop. Pen and paper are ideal because it's easy to write down many ideas and iterate upon them quickly without much overhead. Diving directly into code is obviously very expensive and timely. This is also a good time to start asking yourself "what about your game is special?". If you can't find that special sauce that makes your game unique, that's ok, just keep that in the back of your mind for later. Chances are 75% of the initial ideas you come with will be scrapped or refactored anyways.

The first thing I decided to lock down was the basic game mechanics. I decided to make a 2D side-scrolling platformer with a semi-open world to give the player a sense of explorability. Not dissimilar to my all time favorite game, Super Metroid.

My next step was to take a trip to my favorite local Milk Tea cafe with a stack of white paper and start scribbling some ideas about what the game world would look like. This came pretty naturally given that the main character is a Turd(le). The game was to start within the host's stomach. This seemed like a logical place for a Ninja Turdle to begin his adventures.

But what is a Ninja Turdle even doing in a stomach? What's the purpose of this game? So far, I had only came up with a simple 16x24 pixel sprite that I fell in love with. I'll show it again just for excitement. I hope you enjoy it as much as I do.<br/>
<img src="/images/ninja_large.png"/>

I quickly decided that Mr. Turdle would be fighting parasites and bacteria. This also gives a very wide range of potential monsters and obstacles. Some monsters include tapeworms, ring worms, pin worms, pulsing stomach ulcers, acid pits, various larva, heart worms, etc. The ideas seemed to be never ending, which is always a good start when brainstorming.

I spent a lot of time contemplating on why Mr. Turdle wants to kill all the parasites. My initial idea was that his girlfriend was killed by a parasite and thus revenge was the motive, but this seemed too plain and uncreative. I was at a loss for what the purpose should be for a good month or so when it finally dawned on me that the very host that created Mr. Turdle is being killed by parasites and Mr. Turdle wants to save his host (and creator). It's a pretty simple and obvious story but it also birthed ideas for the ending, which I will not spoil now.

With a mission and approximate story in place I next set out to determine where all this would take place. Would it take place in the host's body only? Where is the host located? I just couldn't come up with enough ideas to justify having the whole game take place in only the body. After a plate of curry and a couple milk teas, my imagination began to flow and I realized that the parasite monster idea could be expanded well beyond the human body. After a very disgusting Google session I discovered a whole plethora of parasites that I decided must be in the game. Some of these include, [parasites that replace the tongue of fish](https://www.google.com/search?q=parasite+the+replaces+fish+tongue&tbm=isch&biw=1746&bih=1150), [snail parasites](https://www.google.com/search?q=snail+parasites&tbm=isch&biw=1746&bih=1150), [caterpillar parasites](https://www.google.com/search?q=caterpillar+parasites&tbm=isch&biw=1746&bih=1150), dung beetles, infected dung, etc. The mind just kind of continues wandering.

With all these new enemies in mind, plus my mental block on creative ways to make the whole game occur within the host's body, I decided to make the whole game take place in the bathroom. The setting is as following. The host is sitting on a toilet. After clearing the host's body, Mr. Turdle will traverse the toilet bowl into the underground pipes. The pipes lead up and through the sink. Upon the sink lies a couple flower pots which lead up into a maze of flower and plants. I figured this is perhaps a good place to throw in some infected insects. Mr. Turdle could also traverse down the sink area into a cat litter box and/or trash can. The idea being that the cat litter box could be a sort of underground maze through the cat litter. Of course each area has it's own special items, weapons, and unique challenges. Perhaps, the item to make Mr. Turdle immune to stomach acid lies in the cabinet under the sink? An anti-acid pill perhaps? Many events began to fall in place over the next few hours, days, and weeks.

The brainstorming session led to the below world overview:
<img src="/images/content/story_2.jpg" width="800px"/>

I was feeling pretty happy with the new scope and size of Ninja Turdle. It seems large enough to be enjoyable, but not too complex to be impossible to build. My next step was to start brainstorming content, items, bosses, power-ups to throw into the world. This was a particularly fun part of the design process for me. The design process was simple, my good friend Steve and I went to my favorite cafe, and we came up with an exhaustive list of power-ups and ideas for the game. We were not worried about fitting it all together, but just to come up with a lot of content that we could prune down later. Below are some samples of the resulting notes.

Sample enemies<br/>
<img src="/images/content/story_3.jpg" width="400px"/><img src="/images/content/story_7.jpg" width="400px"/>

Sample notes<br/>
<img src="/images/content/story_1.jpg" width="800px"/>

This was all I really needed to justify me starting the coding of the game which I will go into the next post. Many of these ideas become more refined overtime. Eventually, I ended up with more detailed story plans. For example, when designing the first area within the stomach, I utilized [Evernote](https://evernote.com/) to capture the step-by-step events. (I actually record all my notes and thoughts in Evernote.)

A sample excerpt of the first ten minutes of game play:

```
- start with nothing
- travel to first mini boss
     - long horizontal room
     - wall boss (massive blob of parasites/worms mashed together)
          - shoots pin worms at you
     - chasing you L to R
     - mario level like room
          - you have no weapons, so you can’t fight
          - the name of the game is “run as fast as you can and don’t get hit or fall"
          - perhaps throw a few designs that look like SMB1 (at least in shape)
          - pits with spikes/acid to fall in (you’ll die because you have low life)
     - exit into room with TURD_TOSS item
     - go back into previous room
     - this time wall boss chases you from R to L
     - the left most door is locked, so you must fight the boss
     - you should face right, (lock view) and fire continuously with your new weapon
     - you must kill boss before getting to left wall, or it will hit you and you’ll die
     - if you beat the boss, the door will open and you can leave
```

I have a running list of events like above for many sections of the game. I strive to write event flows and piece them together over time until I feel that I have a connected game. I don't typically worry about every micro detail along the way and have faith that the details will naturally work themselves out.

Lastly, I start drawing out what each map will look like at a high level. Namely mapping which rooms connects to which rooms. I use this as a basis for designing room layout/design which I will ultimately design sprites for and maps via the Tiled map editor.  

The below image is what a simple example map design will look like for me. Then I fill in more detail such as the style of the room, items, special events, and such.
<img src="/images/content/story_6.jpg" width="500px"/>

This is the basic design process that I go through when designing Ninja Turdle. In short, I like to keep my designing/planning light-weight, and work to get something in place that I can quickly iterate on. In the next posts I will begin covering the actually implementation of these ideas into code.
