/* @pjs preload="Asteroid.png, Asteroid0.png, Asteroid1.png, Asteroid2.png, Rocket.png"; 
 */

/*
 * "Asteroids" by Mark Gillespie, licensed under Creative Commons
 * Attribution-Share Alike 3.0 and GNU GPL license.
 * Work: http://openprocessing.org/visuals/?visualID=106239
 * License:
 * http://creativecommons.org/licenses/by-sa/3.0/
 * http://creativecommons.org/licenses/GPL/2.0/
 */

// Modified from source code at http://www.openprocessing.org/sketch/106239 for
// use in Digi's Wireless Games Kit. This game uses Digi's XBee Game Controller
// library to handle user input by replacing the control handling through
// setting the variables and calling the methods originally done through mouse
// and keyboard input. See the buttonEvent and handleJoystick methods below for
// more details.

// Processing XBee Java Library must be installed
import com.digi.xbee.api.*;
// Digi Kit-of-the-Month XBee Game Controller library
import xbeegamecontroller.*;

Controller controller;

// Change as necessary. Specifies how to address the XBee.
final String XBEE_PORT = "COM5";
final int XBEE_BAUD = 9600;

// Because the joystick included in the kit does not always spring back to
// perfectly centered (~512), we effectively reduce the joystick sensitivity by
// ignoring any values less than this far off of center. This means that, to
// see the joystick as being pushed 'up', for example, the Y value needs to be
// less than or equal to 412 (512 - 100).
final int JOYSTICK_THRESHOLD = 100;

Ship ship;
boolean upPressed = false;//CHANGE LEFT AND RIGHT TO UP AND DOWN( IN SHIP TOO)
boolean downPressed = false;
boolean leftPressed = false;
boolean rightPressed = false;

float shipSpeed = 2;
float rotationAngle = .2;
float bulletSpeed = 10;
int numAsteroids = 1;

int startingRadius = 50;
PImage[] asteroidPics = new PImage[3];

float bgColor = 0;

PImage rocket;


ArrayList<Exhaust> exhaust;
ArrayList<Exhaust> fire;
ArrayList<Bullet> bullets;
ArrayList<Asteroid> asteroids;

PFont font;


int darkCounter;
int darkCounterLimit = 24*2;
int MAX_LIVES = 3;
int lives;
int stage = -1;
int diffCurve = 2;

void setup() {
  textAlign(CENTER, CENTER);

  background(bgColor);
  size(800, 500);
  font = createFont("Cambria", 32);
  asteroidPics[0] = loadImage("Asteroid0.png");
  asteroidPics[1] = loadImage("Asteroid1.png");
  asteroidPics[2] = loadImage("Asteroid2.png");
  rocket = loadImage("Rocket.png");
  frameRate(24);
  lives = 3;
  asteroids = new ArrayList<Asteroid>(0);

  // Connect to the XBee, treat it as an interface to the controller.
  try {
    controller = new Controller(this, XBEE_PORT, XBEE_BAUD);
  } catch (Exception e) {
    /* This would be unexpected. This will usually occur if the serial port
     * does not exist, or was already open.
     */
    System.err.println("Failed to initialize XBee");
    e.printStackTrace();
    System.exit(1);
  }
}

// buttonEvent is automatically called by the XBee Game Controller library when
// button states change.
void buttonEvent(boolean leftButtonPushed, boolean rightButtonPushed) {
  if (leftButtonPushed && stage > -1 && asteroids.size() > 0) {
    // If the left button on the controller is pressed, and the game has begun,
    // try to fire a bullet.
    fireBullet();
  }

  if (rightButtonPushed) {
    // We use the Right button as a replacement for clicking the mouse.
    mousePressed();
  }
}

// Called in the draw() method. This method is used to convert the position of
// the joystick into movement on-screen.
void handleJoystick(int x, int y) {
  int middle = 512;

  // See the comment on the JOYSTICK_THRESHOLD variable at the top of this file
  // for more details on its use here.
  upPressed = (y <= middle - JOYSTICK_THRESHOLD);
  downPressed = (y >= middle + JOYSTICK_THRESHOLD);

  leftPressed = (x <= middle - JOYSTICK_THRESHOLD);
  rightPressed = (x >= middle + JOYSTICK_THRESHOLD);
}

void draw() {
  if (lives >= 0 && asteroids.size()>0) {
    // Handle the joystick position.
    handleJoystick(controller.getX(), controller.getY());

    float theta = heading2D(ship.rotation)+PI/2;
    background(0);

    ship.update(exhaust, fire);
    ship.edges();
    ship.render();
    if (ship.checkCollision(asteroids)) {
      lives--;
      ship = new Ship();
    }

    if (leftPressed) {
      rotate2D(ship.rotation, -rotationAngle);
      //ellipse(100,100,100,100);
    }
    if (rightPressed) {
      rotate2D(ship.rotation, rotationAngle);
    }

    if (upPressed) {
      ship.acceleration = new PVector(0, shipSpeed);
      rotate2D(ship.acceleration, theta);
    } else {
      ship.acceleration = new PVector(0, 0);
    }

    if (downPressed) {
      ship.acceleration = new PVector(0, 0);
    }

    for (Exhaust e : exhaust) {
      e.update();
      e.render();
    }

    for (Exhaust e : fire) {
      e.update();
      e.render();
    }

    for (int i = 0; i < bullets.size (); i++) {
      bullets.get(i).edges();
      if (bullets.get(i).update()) {
        bullets.remove(i);
        i--;
      }
      if (i < 0) {
        break;
      }
      bullets.get(i).render();
      if (bullets.get(i).checkCollision(asteroids)) {
        bullets.remove(i);
        i--;
      }
    }

    while (exhaust.size () > 20) {
      exhaust.remove(0);
    }

    while (fire.size ()>3) {
      fire.remove(0);
    }

    while (bullets.size () > 30) {
      bullets.remove(0);
    }

    for (Asteroid a : asteroids) {
      a.update();
      a.edges();
      a.render();
    }


    for (int i = 0; i < lives; i++) {
      image(rocket, 40*i + 10, ship.r*1.5, 2*ship.r, 3*ship.r);
    }
  } else if (lives < 0) {
    if (darkCounter < darkCounterLimit) {
      background(0);
      darkCounter++;
      for (Asteroid a : asteroids) {
        a.update();
        a.edges();
        a.render();
      }
      fill(0, 255-(darkCounterLimit-darkCounter)*3);
      rect(0, 0, width, height);
    } else {
      background(0);
      for (Asteroid a : asteroids) {
        a.update();
        a.edges();
        a.render();
      }
      image(rocket, width/2 - 5 * ship.r, height/2-7.5*ship.r, 10*ship.r, 15*ship.r);
      textFont(font, 33);
      fill(0, 200);
      text("GAME OVER", width/2, height*.75-1);
      textFont(font, 32);
      fill(255);
      text("GAME OVER", width/2, height*.75);

      String playAgainText = "Click anywhere, or press the Right button, to play again.";
      textFont(font, 16);
      fill(0, 200);
      text(playAgainText, width/2, height*.9-1);
      textFont(font, 15);
      fill(255);
      text(playAgainText, width/2, height*.9);
    }
  } else {
    background(0);
    ship = new Ship();
    ship.render();

    textFont(font, 32);
    fill(255);
    if (stage > -1) {
      text("Stage " + (stage + 1) + " Complete", width/2, height/2);
    } else {
      text("Asteroids", width/2, height/2);
    }

    textFont(font, 15);
    fill(255);
    text("Click anywhere, or press the Right button, to start stage " + (stage + 2), width/2, height*.75);
  }
}

void mousePressed() {
  if (lives < 0) {
    stage = -1;
    lives = 3;
    asteroids = new ArrayList<Asteroid>(0);
  } else  if (asteroids.size()==0) {
    stage++;
    reset();
  }
}


void reset() {
  ship  = new Ship();
  exhaust = new ArrayList<Exhaust>();
  fire = new ArrayList<Exhaust>();
  bullets = new ArrayList<Bullet>();
  asteroids = new ArrayList<Asteroid>();
  for (int i = 0; i <numAsteroids + diffCurve*stage; i++) {
    PVector position = new PVector((int)(Math.random()*width), (int)(Math.random()*height-100));
    asteroids.add(new Asteroid(position, startingRadius, asteroidPics, stage));
  }
  darkCounter = 0;
}

void fireBullet() {
  PVector pos = new PVector(0, ship.r*2);
  rotate2D(pos, heading2D(ship.rotation) + PI/2);
  pos.add(ship.position);
  PVector vel  = new PVector(0, bulletSpeed);
  rotate2D(vel, heading2D(ship.rotation) + PI/2);
  bullets.add(new Bullet(pos, vel));
}

float heading2D(PVector pvect) {
  return (float)(Math.atan2(pvect.y, pvect.x));
}

void rotate2D(PVector v, float theta) {
  float xTemp = v.x;
  v.x = v.x*cos(theta) - v.y*sin(theta);
  v.y = xTemp*sin(theta) + v.y*cos(theta);
}


class Asteroid {
  float radius;
  float omegaLimit = .05;
  PVector position;
  PVector velocity;
  PVector rotation;
  float spin;
  int col = 100;
  PImage pics[];
  PImage pic;
  int stage;
  float dampening = 1;


  public Asteroid(PVector pos, float radius_, PImage[] pics_, int stage_) {
    radius  = radius_;
    stage = stage_;
    position = pos;
    float angle = random(2 * PI);
    velocity = new PVector(cos(angle), sin(angle));
    velocity.mult((50*50)/(radius*radius));
    velocity.mult(sqrt(stage  + 2));
    velocity.mult(dampening);
    angle = random(2 * PI);
    rotation = new PVector(cos(angle), sin(angle));
    spin = (float)(Math.random()*omegaLimit-omegaLimit/2);
    int rnd = (int)(Math.random()*3);
    pics = pics_;
    pic = pics[rnd];
  }

  void breakUp(ArrayList<Asteroid> asteroids) {
    if (radius <= 30) {
      asteroids.remove(this);
    } else if (radius < 33) {
      for (int i = 0; i < 2; i++) {
        float angle = random(2*PI);
        PVector rand = new PVector(radius*sin(angle), radius*cos(angle));
        rand.add(position);
        asteroids.add(new Asteroid(rand, radius*.8, pics, stage));
      }
      asteroids.remove(this);
    } else {
      for (int i = 0; i < 3; i++) {
        float angle = random(2*PI);
        PVector rand = new PVector(radius*sin(angle), radius*cos(angle));
        rand.add(position);
        asteroids.add(new Asteroid(rand, radius*.8, pics, stage));
      }
      asteroids.remove(this);
    }
  }

  void update() {
    position.add(velocity);
    rotate2D(rotation, spin);
  }
  void render() {
    fill(col);
    circ(position.x, position.y);
    if (position.x < radius) {
      circ(position.x + width, position.y);
    } else if (position.x > width-radius) {
      circ( position.x-width, position.y);
    }
    if (position.y < radius) {
      circ(position.x, position.y + height);
    } else if (position.y > height-radius) {
      circ(position.x, position.y-height);
    }
  }

  void edges() {
    if (position.x < 0) {
      position.x = width;
    }
    if (position.y < 0) {
      position.y = height;
    }
    if (position.x > width) {
      position.x = 0;
    }
    if (position.y > height) {
      position.y = 0;
    }
  }


  void circ(float x, float y) {
    pushMatrix();
    translate(x, y);
    rotate(heading2D(rotation)+PI/2);
    // ellipse(0,0,2.1*radius, 1.9*radius);
    image(pic, -radius, -radius, radius*2, radius*2);
    popMatrix();
  }


  float heading2D(PVector pvect) {
    return (float)(Math.atan2(pvect.y, pvect.x));
  }

  void rotate2D(PVector v, float theta) {
    float xTemp = v.x;
    v.x = v.x*cos(theta) - v.y*sin(theta);
    v.y = xTemp*sin(theta) + v.y*cos(theta);
  }
}
/* @pjs preload="laser.png";
 */

class Bullet {
  PVector position;
  PVector velocity;
  int radius = 5;
  int counter = 0;
  int timeOut = 24 * 2;
  float alpha;
  PImage img = loadImage("laser.png");

  public Bullet(PVector pos, PVector vel) {
    position = pos;
    velocity = vel;
    alpha = 255;
  }

  void edges() {
    if (position.x < 0) {
      position.x = width;
    }
    if (position.y < 0) {
      position.y = height;
    }
    if (position.x > width) {
      position.x = 0;
    }
    if (position.y > height) {
      position.y = 0;
    }
  }

  boolean checkCollision(ArrayList<Asteroid> asteroids) {
    for (Asteroid a : asteroids) {
      PVector dist = PVector.sub(position, a.position);
      if (dist.mag() < a.radius) {
        a.breakUp(asteroids);
        return true;
      }
    }
    return false;
  }

  boolean update() {
    alpha *= .9;
    counter++;
    if (counter>=timeOut) {
      return true;
    }
    position.add(velocity);
    return false;
  }

  void render() {
    fill(255);
    pushMatrix();
    translate(position.x, position.y);
    rotate(heading2D(velocity)+PI/2);
    //ellipse(0,0, radius, radius*5);
    image(img, -radius/2, -2*radius, radius, radius*5);
    popMatrix();
  }

  float heading2D(PVector pvect) {
    return (float)(Math.atan2(pvect.y, pvect.x));
  }
}
class Exhaust {
  PVector position;
  PVector velocity;
  float diameter;
  color hugh;

  public Exhaust(PVector pos, PVector vel, color col, int rad) {
    position = pos;
    velocity = vel;
    diameter = (float)(Math.random()*rad);
    hugh = col;
  }

  void render() {
    noStroke();
    fill(hugh);
    ellipse(position.x, position.y, diameter, diameter);
  }

  void update() {
    position.add(velocity);
    velocity.mult(.9);
  }
}
/* @pjs preload="Rocket.png";
 */

class Ship {
  PVector position;
  PVector velocity;
  PVector acceleration;
  PVector rotation;
  float drag = .9;
  float r = 15;
  PImage img = loadImage("Rocket.png");

  public Ship() {
    position = new PVector(width/2, height-50);
    acceleration = new PVector(0, 0);
    velocity = new PVector(0, 0);
    rotation = new PVector(0, 1);
  }

  void update(ArrayList<Exhaust> exhaust, ArrayList<Exhaust> fire) {
    PVector below = new PVector(0, -2*r);
    rotate2D(below, heading2D(rotation)+PI/2);
    below.add(position);
    color grey = color(100, 75);

    int  exhaustVolume = (int)(velocity.mag())+1;
    for (int i = 0; i  <exhaustVolume; i++) {
      float angle = (float)(Math.random()*.5-.25);
      angle += heading2D(rotation);
      PVector outDir = new PVector(cos(angle), sin(angle));
      exhaust.add(new Exhaust(below, outDir, grey, 15));
    }
    for (int i = 0; i  <1; i++) {
      float angle = (float)(Math.random()*.5-.25);
      angle += heading2D(rotation);
      PVector outDir = new PVector(cos(angle), sin(angle));
      outDir.y = 0;
      below.add(outDir);
      below.y-=.5;
      color red = color((int)(200 + Math.random()*55), (int)( 150+Math.random()*105), 50, 250);
      fire.add(new Exhaust(below, outDir, red, 5));
    }
    velocity.add(acceleration);
    velocity.mult(drag);
    velocity.limit(5);
    position.add(velocity);
  }

  void edges() {
    if (position.x < r) {
      position.x = width-r;
    }
    if (position.y < r) {
      position.y = height-r;
    }
    if (position.x > width-r) {
      position.x = r;
    }
    if (position.y > height-r) {
      position.y = r;
    }
  }

  boolean checkCollision(ArrayList<Asteroid> asteroids) {
    for (Asteroid a : asteroids) {
      PVector dist = PVector.sub(a.position, position);
      if (dist.mag() < a.radius + r/2) {
        a.breakUp(asteroids);
        return true;
      }
    }
    return false;
  }

  void render() {
    float theta = heading2D(rotation)  + PI/2;
    theta += PI;

    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    fill(0);

    image(img, -r, -r*1.5, 2*r, 3*r);
    popMatrix();
  }

  float heading2D(PVector pvect) {
    return (float)(Math.atan2(pvect.y, pvect.x));
  }

  void rotate2D(PVector v, float theta) {
    float xTemp = v.x;
    v.x = v.x*cos(theta) - v.y*sin(theta);
    v.y = xTemp*sin(theta) + v.y*cos(theta);
  }
}
