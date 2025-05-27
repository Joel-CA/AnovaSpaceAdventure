int VRx = A0;    // select the input pin for potentiometer 1 (joystick X)
int VRy = A1;    // select the input pin for potentiometer 2 (joystick Y)
int xValue = 0;  // variables to store the values
int yValue = 0;

const int joyStickBtnPin = 2; // select the input pin for button (joystick press down)
int joyStickBtnState = 0; // variables to store button state

void setup() {
  // put your setup code here, to run once:

  //start the serial monitor at a baudRate = 115200
  //ENSURE the serial monitor is set to the same baudRate
  Serial.begin(115200); 
  
  // initialize the joyStickBtnPin as an input:
  pinMode(joyStickBtnPin, INPUT_PULLUP);
}

void loop() {
  // put your main code here, to run repeatedly:
  xValue = analogRead(VRx);
  yValue = analogRead(VRy);
  joyStickBtnState = digitalRead(joyStickBtnPin);

  /* //Useful for interpreting raw values before re-outputting them
  Serial.println("Joystick Vals:");
  Serial.println("X: " + String(xValue) + ", " + 
                 "Y: " + String(yValue) + ", " + 
                 "BTN: " + String(joyStickBtnState));
  */

  /*What is actually used to log to Serial for in-application input*/
  Serial.println(String(xValue) + "," + String(yValue) + "," + String(joyStickBtnState));

  // stop the program for for 1000 milliseconds:
  delay(100);
}
