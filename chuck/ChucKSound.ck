// ===
// Alexey Kalinin, January 2016
// Kadenze Final Project for DSP course
//
// OSC-based sound engine for Processing sketch 
// with interactive platonic solid figure - dodecahedron.
//

// Settings for OSC
OscIn oin;         // make an OSC receiver
6449 => oin.port;  // set port #
OscMsg msg;        // message holder

// Expected messages, sync with Processing sketch
oin.addAddress( "/kadenze/string/, iffff" );
oin.addAddress( "/kadenze/peg/, ifff" );
oin.addAddress( "/kadenze/bang/, f" );
oin.addAddress( "/kadenze/destroy/" );
oin.addAddress( "/kadenze/tune/" );
oin.addAddress( "/kadenze/reset/" );

// Sound gens
StifKarp skarp[30];     // strings sound, array size == number of strings
BandedWG banded_wg[5];  // main bang sound (global shake) 
Shakers shaker_bang;    // additional bang sound (precussion)
ModalBar bars[20];      // main sound for pegs, array size == number of pegs 
Shakers shaker_peg;     // additional sound for pegs (percussion attack)
Shakers shaker_tuning;  // sound for peg rotation during tuning
BlowBotl botl;          // noisy sound for deconstruction stage
Noise noise;            // additional filtered noise for deconstruction stage

// Common chain
Pan2 pan[30]; // pan for strings
Pan2 pan_pegs[20]; // pan for pegs
Gain main_mix[2] => JCRev rev[2] => dac;  

0.2 => rev[0].mix;
0.2 => rev[1].mix;
1.0/1.3 => main_mix[0].gain  => main_mix[1].gain;

// Sound gens settings
Gain noiseGain;         
0 => noiseGain.gain;
LPF lpf_noise;
700 => lpf_noise.freq; // make noise less sharp
Pan2 forNoise;
noise => lpf_noise => noiseGain => forNoise => main_mix;

Pan2 shaker_pan;
14 => shaker_peg.preset; 
shaker_peg => shaker_pan => main_mix;

5 => shaker_bang.preset; 
shaker_bang => main_mix;

3 => shaker_tuning.preset; 
shaker_tuning => Gain tuning_gain => main_mix;
0.4 => tuning_gain.gain;

240 => botl.freq;
Pan2 forBotl;
botl =>  forBotl => main_mix;

PitShift pitchShifter;
for ( 0 => int i; i < banded_wg.cap(); i++) { 
     3 => banded_wg[i].preset;
     0.6 => pitchShifter.gain;   
     banded_wg[i] => pitchShifter => main_mix;   
}

for ( 0 => int i; i < skarp.cap(); i++) {     
     skarp[i] => pan[i] => main_mix;   
}

for ( 0 => int i; i < bars.cap(); i++) {     
     4 => bars[i].preset;  
     bars[i] => pan_pegs[i] => main_mix;     
}
// 

0 => int isBang;    // bang flag (for muting some sources)
1 => int condition; // for syncing with Processing sketch stop

while(condition)
{
    oin => now;   // wait for any OSC

    while(oin.recv(msg) != 0)
    {
        //<<< "got message:", msg.address, msg.typetag >>>;
        if (msg.address == "/kadenze/string/") {
            msg.getInt(0)   => int string_id;   
            msg.getFloat(1) => float pitch;
            msg.getFloat(2) => float amp;
            msg.getFloat(3) => float panning;
            msg.getFloat(4) => float position;
 
            /*spork ~ */  stringSound(string_id, pitch, amp, panning, position);
        }
        
        if (msg.address == "/kadenze/peg/") {
            msg.getInt(0)   => int peg_id;
            msg.getFloat(1) => float pitch;
            msg.getFloat(2) => float amp;
            msg.getFloat(3) => float pan;
            
            /*spork ~ */   pegSound(peg_id, pitch, amp, pan);
        }
        
        if (msg.address == "/kadenze/tune/") {
            tuneSound();
        }
        
        if (msg.address == "/kadenze/bang/") {
            msg.getFloat(0)   => float freq_divider;

            // rise bang flag here and set back to 0 in unlock call from bangSound
            1 => isBang; 
            bangSound(freq_divider);
        }
        
        if (msg.address == "/kadenze/destroy/") {
            //1 => isBang;
            //bangSound();
            destroySound();
        }
        
        if (msg.address == "/kadenze/reset/") {
            0 => condition; // exiting
        }
    }
}


fun void stringSound(int index, float pitch, float amp, float panning, float position) {
      panning => pan[index].pan;
      0.1 => skarp[index].stretch;
      position => skarp[index].pickupPosition; 
      pitch => skarp[index].freq;
      amp => skarp[index].noteOn;      
}

fun void pegSound(int peg_id, float pitch, float amp, float panning) {
      panning => pan_pegs[peg_id].pan;
      panning => shaker_pan.pan;
      // Under if-condition - limitations for Bang stage
      if (isBang != 1) 2 => shaker_peg.noteOn;
      pitch => bars[peg_id].freq;
      if (isBang == 1) amp/3 => bars[peg_id].noteOn;
      else amp => bars[peg_id].noteOn;
}

fun void tuneSound() {
      // add more randmoness for rolling sound
      Math.random2(200,1000) => shaker_tuning.freq;
      Math.random2(1,5) => shaker_tuning.objects;
      1 => shaker_tuning.noteOn;
}

fun void bangSound(float _freq_divider) {
      // percussion attack sound
      // trunckate to int for smooth pitch change 
      _freq_divider $ int => int freq_divider; 
    
      10 => shaker_bang.noteOn;
      (440/freq_divider) =>  float base_freq; 
      <<< "base_freq " + base_freq>>>; 
      
      base_freq => banded_wg[0].freq;
      .5  => banded_wg[0].noteOn;
    
      // "Risset's style" freq settings
      base_freq + 0.25 => banded_wg[1].freq;
      .5  => banded_wg[1].noteOn;

      // "Risset's style" freq settings
      base_freq/2 + 20.25 => banded_wg[2].freq;
      1.  => banded_wg[2].noteOn;
    
      base_freq/2 + 20.0 => banded_wg[3].freq;
      1.  => banded_wg[3].noteOn;
    
      base_freq/4 + 30 => banded_wg[4].freq; // 140
      .5  => banded_wg[4].noteOn;
      // intentionally no noteOff messages here - let it drone!
  
      // low bang flag 
      spork ~ unlock();

}

fun void unlock() {
      // wait a little bit and low bang flag
      100::ms => now;
      0 => isBang;
}

fun void destroySound() {
      // creating strange noise here
      0.2 => noiseGain.gain;
    
      0.3 => botl.vibratoGain;
      0.7 => botl.startBlowing;
      // no noteOff messages - its the end of the performance
    
     spork ~ drifftingNoise();
     spork ~ pitchShift();
}

fun void drifftingNoise() {
    0 => float counter;   
    while (condition) {
       0.5 * Math.sin(counter) => forBotl.pan;
       -0.5 * Math.sin(counter) => forNoise.pan;
       0.1 +=> counter;
       1::second => now;
    }
}

fun void pitchShift() {
    1. => pitchShifter.mix;
    1 => float shift;
    while (shift > 0) {
       shift => pitchShifter.shift;
       0.01 -=> shift;
       50::ms => now;
    }
}
