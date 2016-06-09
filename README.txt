Dodecahedron.
Alexey Kalinin, 2016

*SUMMARY*
3D dodecahedron presented as string plucked instrument. Edges act as strings, vertices act as pegs.
Each part of the figure has one or several functions and sounds.

*PARTS OF THE CONSTRUCTION*
Strings.
Each string connected to the two pegs. Pitch of the string initially has settings in the code,
but it can be changed by using pegs. Each of two pegs has same effect on the string and can shift 
it's pitch up or down.
Characteristics of string's sound depend on plucking position (far or close to the one of the pegs)
and velocity of plucking (speed of mouse movement). These characteristics is also effects on string 
animation.
Each string has it's own sound gen in Chuck programm (StifKarp).

Pegs.
Graphically presented as small spheres.
Pegs has several functions.
1. Tuning for EACH string which is connected to the peg by using mouse wheel on the selected peg.
So, for dodecahedron each peg change pitch for 3 string at the same time and same shift
(yes, it's hard to tune this whole device). Tuning process was animated like rotation of the
sphere and little vibration and noise from connected strings. One of the Shakers presets with
some randomness is used to make sound here.
2. Hit on the peg (mouse click) produces complex sound. It consist short initial attack of
percusion sound, then bar-like sound (main) and little but hearable vibration from connected strings.
Pitch of main sounds is mean of the pitch of each peg's strings. Hit animated as quick jitter of peg's
sphere and vibration of connected strings.
At ChucK side each pegs sound consist three sound generator: Model Bar, Shaker for hit sound, 
and another one Shaker, but with different settings for tuning mode.

Additionaly, here is a two common "sound modes" for the whole construction.
1. Bang or Global shake. Called by pressing key "b" on keyboard.
In this mode all parts of figure (pegs and strings) sounds almost at the same time (with little 
constraint at the Chuck side, for loudness limitations). Additionaly, Bang generates it's own unique
complex sound.  Main part consist five BandedWG gens with the same preset, but different
frequencies setup (Risset's style), which create etherial long drone. Attack part consist single-shot
sound from Shakers.
Bang animated as quick shake of whole construction.

2. Destroy - special mode for end of performance (and more drama effect). Called by pressing "d" on keyboard.
Sound of destroy mode consist Bang sound (with limitations) and it's own unique sound. 
Two noisy generators was used here: lpf-filtered Noise and BlowBotl.
During the Destroy mode total deconstruction of the model happens.


*TECH STUFF*
Animation and main logic presented in Processing sketch. ChucK used as sound engine and recieve 
OSC message from main sketch. 
Besides standard Processing stuff (draw, setup, mouse/keys handling) sketch contain three class:
Peg, String and SoundManager. Peg and String implements all functionality (except sound) for 
corresponding objects and SoundManager handle with OSC communications.
Used: OS Windows 7, Processing 3.0.1 with oscP5 library, Chuck 1.3.5.2-beta-3 (chimera) 32 bit.

*USE AND KEYS*
Plucking the string - quick mousr drag across the string (with left key hold);
Hit the Peg - click on the peg;
Tune the string - move mouse wheel while cursor above desired peg. 
s - test all string in circle
p - test all pegs in circle
r - start/stop rotation
+/- - increase/decrease speed of rotation
Ctrl+MouseWheel - zoom in/out
b - Bang
d - Destroy
x - exit with closing Chuck patch

Thank you!
Al.

EOF.
