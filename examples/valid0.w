// useless comment

int double(int a){
  return 2 * a;
}

int sum3(int a){
  return a + 3;
}

void write10(){
  write(10);
  return ;
}

int main(){
  int a;
  int b;
  float c;
  float d;

  a = double(10);
  b = sum3(a);
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
  write10();

  return 0;
}