int a;
int main(){
  int b;
  read(b);
  a = (b + 2 + (3 * 4))/5;
  while(a < 3){
    if(a % 2 == 0){
      write(2);
    }
    else {
      write(1);
    }
    a = a + 1;
  }
  return 0;
}