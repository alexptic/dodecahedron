import netP5.*;
import oscP5.*;

ArrayList<SoundString> strings = new ArrayList<SoundString>(); 
ArrayList<Peg> pegs = new ArrayList<Peg>(); 

float eyeX, eyeY, eyeZ;
float ang = 0;
float ang_step = 0.05;
int z_distance = 800;
boolean rotateCamera = false;
boolean allowZoom = false;
int bg_color_inc = 0;
int checkTimer = 0;

SoundManager soundManager;


class SoundManager {
    private OscP5 oscP5;
    private final int remotePort = 6449;

    /* a NetAddress contains the ip address and port number of a remote location in the network. */ 
    private NetAddress myBroadcastLocation; 

    SoundManager(){
            oscP5 = new OscP5(this,2000);
            myBroadcastLocation = new NetAddress("127.0.0.1", remotePort);
    }; 

    // string pluck 
    void play(int string_id, float pitch, float amp, float pan, float pluck_position) {
            OscMessage myOscMessage = new OscMessage("/kadenze/string/");
            myOscMessage.add(string_id); 
            myOscMessage.add(pitch); 
            myOscMessage.add(amp/50); // !!!
            myOscMessage.add(pan); 
            myOscMessage.add(pluck_position); 
            oscP5.send(myOscMessage, myBroadcastLocation);
    }

    // peg hit
    void play(int peg_id, float pitch, float velocity, float pan) {
            OscMessage myOscMessage = new OscMessage("/kadenze/peg/"); 
            myOscMessage.add(peg_id); 
            myOscMessage.add(pitch); 
            myOscMessage.add(velocity); 
            myOscMessage.add(pan); 
            oscP5.send(myOscMessage, myBroadcastLocation);
    }
    
    // tune sound
    void playTune() {
            OscMessage myOscMessage = new OscMessage("/kadenze/tune/"); 
            oscP5.send(myOscMessage, myBroadcastLocation);
    }
    
    // bang sound
    void playBang(float freq_divider) {
            OscMessage myOscMessage = new OscMessage("/kadenze/bang/"); 
            myOscMessage.add(freq_divider);
            oscP5.send(myOscMessage, myBroadcastLocation);
    }
    
    // destroy
    void playDestroy() {
            OscMessage myOscMessage = new OscMessage("/kadenze/destroy/"); 
            oscP5.send(myOscMessage, myBroadcastLocation);
    }
    
    // reset chuck - experimental
    void sendReset() {
            OscMessage myOscMessage = new OscMessage("/kadenze/reset/"); 
            oscP5.send(myOscMessage, myBroadcastLocation);
    }

    

}

class SoundString {
    private float x0, x1;
    private float y0, y1;
    private float z0, z1;
    
    float pitch;
    private float string_length;
    private boolean plucked = false;
    private Peg peg0, peg1; //pegs connected to
    private int string_id;  //for osc-chuck identification
    private boolean destroyMode = false; 
    boolean isHidden = false;

    //for oscillating string drawing
    private int t = 0;        // time since pluck
    private int m_tot = 10;   // harmonics
    private float c = 400;    // speed
    private float d_position; // x position of pluck
    private float amp;        // amplitude
    private float damp = 1.1; // damping constant 
    
    private int pluckTime = 0;
    
    SoundString(Peg _peg0, Peg _peg1, float _pitch) {
            peg0 = _peg0;
            peg1 = _peg1;

            x0 = peg0.x;
            y0 = peg0.y;
            z0 = peg0.z;

            x1 = peg1.x;
            y1 = peg1.y;
            z1 = peg1.z;

            peg0.addString(this);
            peg1.addString(this);

            pitch =_pitch;

            string_length = dist(x0,y0,z0,x1,y1,z1);

            // get string id as current size of list :/
            string_id = strings.size(); 
    }
    
    // use pluck positon from outside
    void pluck(float _amp, float _d) {
            d_position = _d;
            pluck(_amp); 
    }
    
    // use calculated pluck position
    void pluck(float _amp) {
            if (isHidden) return;
            //if (plucked) return;
            if ( millis() - pluckTime < 100 ) return;

            //print("Plucking string with pitch " + pitch + "\n");        
            amp = _amp;
            plucked = true;
            
            float pan = 0;
            float pluck_point = (screenX(x0,y0,z0) + 0.5*(screenX(x1,y1,z1) - screenX(x0,y0,z0))) - 0.5*width;
            pan = map (pluck_point, -300,300, -0.3,0.3);
                       
            //TODO: hide string_id
            soundManager.play(string_id, pitch, amp, pan, d_position);
            pluckTime = millis();

            //TODO: check it..
            //peg0.resonate(this, amp);
            //peg1.resonate(this, amp);
    }

    float pitchShift(float shift) {
            pitch += shift; 
            return pitch;
    }
    
    void setPitch(float new_pitch) {
            pitch = new_pitch;
    }
    
    void hide() {
           isHidden = true;
    }
    
    void show() {
           isHidden = false;
           if (peg0.isHidden) peg0.show();
           if (peg1.isHidden) peg1.show();
    }
    
    void destroy() {
           destroyMode = true;
    }

    void draw() {
        if (isHidden) return;
        if (plucked) {
                //stroke(255*amp,0,0);
                stroke(0,0,0);
                float d = d_position*string_length;
                float w = PI*(c/string_length);

                if(destroyMode) {
                    amp = random(100,160);
                    c = 10;
                    
                    x0 = peg0.x;
                    y0 = peg0.y;
                    z0 = peg0.z;
                    
                    x1 = peg1.x;
                    y1 = peg1.y;
                    z1 = peg1.z;
                    
                    string_length = dist(x0,y0,z0,x1,y1,z1);
                }


                t++;
                amp/= damp;
                
                // DRAW OSILLATING STRING
                pushMatrix(); //save actual space

                // Now move coord system to the first point of the string
                // and X-axis at same direction and position as string itself
                translate(x0,y0,z0); //move coords system to the first point 
                // get angle for rotate system around Z-axis
                PVector vx = new PVector (1,0,0);  // X-axis
                PVector vp = new PVector (x1 - x0,y1 - y0, 0); // dest vector
                float alpha_z = PVector.angleBetween(vx,vp);  // get target angle for rotation  

                // direction of rotation depends on source coords
                int direction_z = ( y0 > y1 ) ? -1 : 1;
                rotateZ(direction_z * alpha_z);
                           
                // Now move coord system around Y-axis for handle with Z-direction
                // get x1 for new coord system (after first rotate)
                float x_projection = abs((x1 - x0)/cos(direction_z*alpha_z)); // projection (from triangle solution)
                PVector vp2 = new PVector (x_projection,0, z1 - z0);     // dest vector (Z!!!!) 
                float alpha_y = PVector.angleBetween(vx,vp2);       // get angle

                int direction_y = ( z0 < z1 ) ? -1 : 1;
                rotateY(direction_y * alpha_y);                                  
                
                //strokeWeight(2);
                if(!destroyMode) noFill();
                beginShape();
                // Interate from x = 0 to length because here the coord system start at the begining of the string,
                // no worry about actual position of the string in 3D space 
                for (float x = 0 ; x < string_length; x += 5) {
                     // Maths from http://www.oberlin.edu/faculty/brichard/Apples/StringsPage.html
                     float sum = 0;
                     // Sum of harmonics
                     for (int m = 1; m <= m_tot; ++m) {
                         sum += (1.0/(m*m)*sin((m*PI*d)/string_length)*sin((m*PI*x)/string_length)*cos(m*w*t));
                     }
                     float y = (1.5*amp*string_length*string_length)/(PI*PI*d*(string_length - d))*sum;
                     vertex(x,y);
                }
                endShape();
                popMatrix();

                // stop oscillating
                if (amp <= 0.5) { 
                    t = 0;
                    plucked = false;
                }
        } // plucked
        else {
                stroke(0,0,0);
                line(x0,y0,z0, x1,y1,z1);
        }

    }

    // not so cute but OK for now (lot of compromise here)
    void getPluckPosition() {
              float X1 = screenX(x0,y0,z0);
              float Y1 = screenY(x0,y0,z0);
            
              float X2 = screenX(x1,y1,z1);
              float Y2 = screenY(x1,y1,z1);
              //for vertical strings
              if (X1 == X2) {
                    d_position = 0.5;
                    return;
              }
              //find cross-point of the string (line) and _|_ from pluck position (point)
              float X = ( X1*(Y2-Y1)*(Y2-Y1)-mouseX*(X1-X2)+ (mouseY-Y1)*(Y2-Y1)*(X2-X1) ) / ( (Y2-Y1)*(Y2-Y1) - (X1 - X2) );
              float Y = (X - X1)*(Y2 - Y1)/(X2 - X1) + Y1;
              //find ratio point on the string and length of the string 
              d_position = dist(X,Y,X1,Y1)/dist(X1,Y1,X2,Y2);
    }

    boolean isHasMouse() {
            if (isHidden) return false;
            //http://algolist.manual.ru/maths/geom/distance/pointline.php       
            float d_1 = (screenY(x0,y0,z0) - screenY(x1,y1,z1))*mouseX + (screenX(x1,y1,z1) - screenX(x0,y0,z0))*mouseY
                    +(screenX(x0,y0,z0) * screenY(x1,y1,z1) - screenX(x1,y1,z1) * screenY(x0,y0,z0)) ;
            float d_2 = dist( screenX(x0,y0,z0), screenY(x0,y0,z0), screenX(x1,y1,z1), screenY(x1,y1,z1));
            float distance = d_1/d_2;

            // real rock'n'roll :-D
            boolean withinRect = 
               (((mouseX >= screenX(x0,y0,z0)) && (mouseX <= screenX(x1,y1,z1)) && (screenX(x0,y0,z0) <= screenX(x1,y1,z1)) ||
               (mouseX <= screenX(x0,y0,z0)) && (mouseX >= screenX(x1,y1,z1)) && (screenX(x0,y0,z0) >= screenX(x1,y1,z1))) &&
               ((mouseY >= screenY(x0,y0,z0)) && (mouseY <= screenY(x1,y1,z1)) && (screenY(x0,y0,z0) <= screenY(x1,y1,z1)) ||
               (mouseY <= screenY(x0,y0,z0)) && (mouseY >= screenY(x1,y1,z1)) && (screenY(x0,y0,z0) >= screenY(x1,y1,z1))) ||
               ((mouseY <= screenY(x0,y0,z0) && (mouseY >= screenY(x1,y1,z1)) && (screenX(x0,y0,z0) == screenX(x1,y1,z1)))) || 
               ((mouseX >= screenX(x0,y0,z0) && (mouseX <= screenX(x1,y1,z1)) && (screenY(x0,y0,z0) == screenY(x1,y1,z1)))) 
               ); 
            
            getPluckPosition();
          
            return (abs(distance) <= 10) && withinRect;
    }
}

class Peg {
        private ArrayList<SoundString> connectedStrings = new ArrayList<SoundString>();
        float x;
        float y;
        float z;
        private int peg_id;
        private float pitch;
        boolean isHidden = false;
        private boolean destroyMode = false;

        final private int targetRadius = 10;
        private int currentRadius = 0;
        private boolean tuneMode = false;
        private int tuneModeTimer = 0;
        private int tuneDirection = 0;

        private boolean hitMode = false;
        private int hitTimer  = 0;

        Peg(float _x, float _y, float _z) {
                connectedStrings.clear();
                x = _x;
                y = _y;
                z = _z;

                pitch = random(210,240);
                // get peg id as current size of list :/
                peg_id = pegs.size(); 
        }

        void addString(SoundString _string) {
                connectedStrings.add(_string);
        }
        
        void hide() {
                isHidden = true;
        }
    
        void show() {
                isHidden = false;
        }
        
        void destroy() {
                destroyMode = true;
        }

        void draw() {
                if (isHidden) return;
          
                fill(255);
                if (tuneMode) {
                        //fill(255,0,0);
                        if (millis() - tuneModeTimer > 500 ) tuneMode = false;
                }
                
                strokeWeight(0.5);
                if (z_distance > 600) {
                        sphereDetail(10);
                        noStroke();
                }

                pushMatrix();
                if (hitMode) {
                        translate(random(x-1,x+1),random(y-1,y+1),random(z-1,z+1));
                        if (millis() - hitTimer > 500 ) hitMode = false;
                }
                else {
                        if (destroyMode) {
                                x += random(-10,10);
                                y += random(-10,10);
                                z += random(-10,10);
                        }
                        

                        
                        translate(x,y,z);
                }

                if (tuneMode) rotateY(PI * tuneDirection * frameCount / 500);
                currentRadius += (currentRadius != targetRadius) ? 1 : 0; 


                sphere(currentRadius);
                //text(peg_id,0,0,0);
                popMatrix();
        }

        void hit(float velocity) {
                hitMode = true;
                hitTimer = millis();
                
                // experimental - mean of strings pitch
                float sum_pitch = 0;
                for (int i = 0; i < connectedStrings.size(); i++) {
                        sum_pitch += connectedStrings.get(i).pitch;
                }
                pitch = sum_pitch/connectedStrings.size();
                
                float pan = 0;
                float pluck_point = screenX(x,y,z) - 0.5*width;
                pan = map (pluck_point, -300,300, -0.3,0.3);

                soundManager.play(peg_id, pitch, velocity, pan); 
                for (int i = 0; i < connectedStrings.size(); i++) {
                        if (connectedStrings.get(i).isHidden) connectedStrings.get(i).show();
                        if (destroyMode) connectedStrings.get(i).destroy(); 
                                          
                        connectedStrings.get(i).pluck(5, 0.1);
                }
        }

        // invokes from connected string and leads to resonate for other connected
        void resonate(SoundString source_string, float amp) {
                // TODO: need tuninig
                float resonance_dumping = 2.3; // higher -> harder
                amp /= resonance_dumping;
                for (int i = 0; i < connectedStrings.size(); i++) {
                        if (connectedStrings.get(i) != source_string) { // do not pluck back source string
                                connectedStrings.get(i).pluck(amp, 0.01);
                        } 
                }
        }

        void tune(float shift) {
                if (destroyMode) return;
          
                tuneMode = true;
                tuneModeTimer = millis();
                tuneDirection = (int)shift;
                for (int i = 0; i < connectedStrings.size(); i++) {
                        connectedStrings.get(i).pitchShift(shift);
                        connectedStrings.get(i).pluck(10,0.01);
                        soundManager.playTune(); 
                }
        }

        boolean isHasMouse() {
                return (abs(mouseX - screenX(x,y,z)) <= targetRadius) && (abs(mouseY - screenY(x,y,z)) <=targetRadius);
        }
}


void setup() {
        size(1280, 720, P3D);
        frameRate(30);
        soundManager = new SoundManager();

        // camera view settings
        eyeX = width/2;
        eyeY = 500; 
        eyeZ = z_distance;

        pegs.clear();
        float phi = 1.618033; //golden mean
        //Centrum -> 512 380 100 length 200
        //https://en.wikipedia.org/wiki/Regular_dodecahedron 
        //https://processing.org/discourse/beta/num_1272064104.html
        float x0 = 512;
        float y0 = 380;
        float z0 = 100;
        float length0 = 200;

        pegs.add(new Peg(x0, y0+length0*1/phi, z0+length0*phi)); // 0 
        pegs.add(new Peg(x0, y0+length0*1/phi, z0-length0*phi)); // 1
        pegs.add(new Peg(x0, y0-length0*1/phi, z0+length0*phi)); // 2
        pegs.add(new Peg(x0, y0-length0*1/phi, z0-length0*phi)); // 3
        pegs.add(new Peg(x0+length0*phi, y0, z0+length0*1/phi)); // 4
        pegs.add(new Peg(x0+length0*phi, y0, z0-length0*1/phi)); // 5
        pegs.add(new Peg(x0-length0*phi, y0, z0+length0*1/phi)); // 6
        pegs.add(new Peg(x0-length0*phi, y0, z0-length0*1/phi)); // 7 
        pegs.add(new Peg(x0+length0*1/phi, y0+length0*phi, z0)); // 8
        pegs.add(new Peg(x0+length0*1/phi, y0-length0*phi, z0)); // 9
        pegs.add(new Peg(x0-length0*1/phi, y0+length0*phi, z0)); // 10
        pegs.add(new Peg(x0-length0*1/phi, y0-length0*phi, z0)); // 11
        pegs.add(new Peg(x0+length0, y0+length0, z0+length0));   // 12
        pegs.add(new Peg(x0+length0, y0+length0, z0-length0));   // 13
        pegs.add(new Peg(x0+length0, y0-length0, z0+length0));   // 14
        pegs.add(new Peg(x0+length0, y0-length0, z0-length0));   // 15
        pegs.add(new Peg(x0-length0, y0+length0, z0+length0));   // 16
        pegs.add(new Peg(x0-length0, y0+length0, z0-length0));   // 17
        pegs.add(new Peg(x0-length0, y0-length0, z0+length0));   // 18
        pegs.add(new Peg(x0-length0, y0-length0, z0-length0));   // 19

        // C-whole tone scale
        strings.add( new SoundString( pegs.get(0),  pegs.get(2),  130.81)  );
        strings.add( new SoundString( pegs.get(14), pegs.get(2),  146.83)  );
        strings.add( new SoundString( pegs.get(4),  pegs.get(14), 164.81)  );
        strings.add( new SoundString( pegs.get(4),  pegs.get(12), 185.00)  );
        strings.add( new SoundString( pegs.get(12), pegs.get(0),  207.65)  );
        strings.add( new SoundString( pegs.get(16), pegs.get(0),  233.08)  );
        strings.add( new SoundString( pegs.get(6),  pegs.get(16), 261.63)  );
        strings.add( new SoundString( pegs.get(6),  pegs.get(18), 293.66)  );
        strings.add( new SoundString( pegs.get(18), pegs.get(2),  329.63)  );
        strings.add( new SoundString( pegs.get(7),  pegs.get(6),  370.00)  );
        strings.add( new SoundString( pegs.get(9),  pegs.get(14), 415.30)  );
        strings.add( new SoundString( pegs.get(11), pegs.get(9),  466.16)  );
        strings.add( new SoundString( pegs.get(11), pegs.get(18), 523.25)  );
        strings.add( new SoundString( pegs.get(19), pegs.get(11), 587.33)  );
        strings.add( new SoundString( pegs.get(8),  pegs.get(12), 659.26)  );
        strings.add( new SoundString( pegs.get(10), pegs.get(8),  740.00)  );
        strings.add( new SoundString( pegs.get(10), pegs.get(16), 830.60)  );
        strings.add( new SoundString( pegs.get(17), pegs.get(10), 932.33)  );
        strings.add( new SoundString( pegs.get(5),  pegs.get(4),  830.60)  );
        strings.add( new SoundString( pegs.get(13), pegs.get(8),  740.00)  );
        strings.add( new SoundString( pegs.get(1),  pegs.get(3),  659.26)  );
        strings.add( new SoundString( pegs.get(3),  pegs.get(19), 587.33)  );
        strings.add( new SoundString( pegs.get(19), pegs.get(7),  523.25)  );
        strings.add( new SoundString( pegs.get(17), pegs.get(7),  466.16)  );
        strings.add( new SoundString( pegs.get(1),  pegs.get(17), 415.30)  );
        strings.add( new SoundString( pegs.get(15), pegs.get(9),  370.00)  );
        strings.add( new SoundString( pegs.get(3),  pegs.get(15), 329.63)  );
        strings.add( new SoundString( pegs.get(15), pegs.get(5),  293.66)  );
        strings.add( new SoundString( pegs.get(13), pegs.get(5),  261.63)  );
        strings.add( new SoundString( pegs.get(1),  pegs.get(13), 233.08)  );
        

        // hide all
        for (int i = 0; i < strings.size(); i++) {
                strings.get(i).hide();
        }

        //...except first peg
        for (int i = 1; i < pegs.size(); i++) {
                pegs.get(i).hide();
        }


        // for video-audio sync
        soundManager.play(0, 440, 1., 0);   
        checkTimer = millis();
}
 
int prev_divider = 1;
void draw() {
  
        float blue_component = 255 - bg_color_inc/5;
        if(pegs.get(0).destroyMode) { 
                fill(255,22);
                noCursor();
                // speed up twisting
                ang_step += 0.1;
        }
        else {
                // different parts fade with different speed (blue longest)
                background(255 - bg_color_inc/2,255 - bg_color_inc/3, blue_component); // 2 3 5
        }
        
        // check for auto-bang if prev_divider (int) changes
        float freq_divider = map(blue_component, 255, 50, 1, 4);
        if ( int(freq_divider) != prev_divider) {
              prev_divider = int(freq_divider);
              bangAllPeg();
        }

        // light stuff
        pointLight(60, 223, 255, width/2, 0, 400); 
        lightSpecular(bg_color_inc/2, 0, 0);
        // turn ligh source - direction depends on the blue part of bg light (tottal madness)
        directionalLight(255, 0, 0, 0, -1,  - 1 *(1 - blue_component/255.0)); 

        // camera rotation 
        camera(eyeX, eyeY-100, eyeZ, 500, 400, 100, 0, 1, 0);
        if (rotateCamera) ang += ang_step;
        if (ang>=360) ang=0;
        eyeX = 500 + z_distance*sin(radians(ang));
        eyeZ = 100 + z_distance*cos(radians(ang));

        strokeWeight(2);
        for (int i = 0; i < strings.size(); i++) {
                strings.get(i).draw();
        }

        for (int i = 0; i < pegs.size(); i++) {
                pegs.get(i).draw();
        }
        
        // getting darker
        if ((millis() - checkTimer > 300) && (!pegs.get(0).destroyMode) && rotateCamera) {
            checkTimer = millis();
            bg_color_inc += 2; 
            //if (bg_color_inc >= 255) destroy();
        }
        
        //TODO: inner sphere
        /*
        pushMatrix();
        translate(512,380,100);
        noStroke();
        sphere(1.63*100); 
        popMatrix();
        */
}

int iter = 0;
void testPluck() {
        int index = iter++ % strings.size();
        strings.get(index).pluck(50, 0.5);     
}

void testPeg() {
        int index = iter++ % pegs.size();
        pegs.get(index).hit(1.);     
}


void bangAllPeg() {
        float blue_component = 255 - bg_color_inc/5;
        // map blur part of bg to tone of global shake (its going deeper)
        float freq_divider = map(blue_component, 255, 50, 1, 4);
        
        // lowering freq for global bang sound
        // send divider to ChucK instead of real freq
        soundManager.playBang(freq_divider);
        for (int i = 0; i < pegs.size(); i++) {
                pegs.get(i).hit(1.);
        }
}

void destroy() {
        soundManager.playDestroy();   
        for (int i = 0; i < pegs.size(); i++) {
                pegs.get(i).destroy(); 
                pegs.get(i).hit(.5);
        }
}


void keyPressed() {
        if (key == 's') testPluck();
        if (key == 'p') testPeg();
        if (key == 'b') bangAllPeg(); 
        if (key == 'd') destroy(); 
        if (key == 'r') rotateCamera = !rotateCamera; 
        if (key == '+') ang_step += 0.05;
        if (key == '-') ang_step -= 0.05; 
        if (keyCode == CONTROL)  allowZoom = true; 
        if (key == 'x') {
                soundManager.sendReset();
                exit();
        }
}

void keyReleased() {
        allowZoom = false;
}

void mouseWheel(MouseEvent event) {
        int index =-1;
        for (int i = 0; i < pegs.size(); i++) {
                boolean res = pegs.get(i).isHasMouse();
                if (res) {
                        index = i;
                        break;
                }
        }

        if (index != -1) {
                final int tune_step = 5; 
                float e = event.getCount();
                pegs.get(index).tune(e*tune_step);
        }
        else {
                if (allowZoom)
                        z_distance +=10*event.getCount();
        }
}

void mouseClicked() {
        int index =-1;
        for (int i = 0; i < pegs.size(); i++) {
                boolean res = pegs.get(i).isHasMouse();
                if (res) {
                        index = i;
                        break;
                }
        }

        if (index != -1) {
                pegs.get(index).hit(1.);
        }
}

//void mouseMoved() {
void mouseDragged() {
        int index =-1;
        //TODO: check for Z
        for (int i = 0; i < strings.size(); i++) {
                boolean res = strings.get(i).isHasMouse();
                if (res) {
                        index = i;
                        break;
                }
        }

        if (index != -1) {
                float amp = map(dist(pmouseX,pmouseY,mouseX,mouseY), 1, 20, 0, 50);
                if (amp > 50) amp = 50;
                strings.get(index).pluck(amp);
        }
}