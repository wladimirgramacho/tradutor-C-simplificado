// useless comment

int func(){
  return 1234;
}

int main(){
  int a;
  int b;
  float c;
  float d;

  a = 10;
  b = func();
  c = 3.14;

  while(a <=  20){
    a = a + 1;
  }
  if(b == 1){
    c = 3.0;
  }
  else {
    d = d + 4.5;
  }
  write(a);
  write(b);
  write(c);
  write(d);

  return 0;
}