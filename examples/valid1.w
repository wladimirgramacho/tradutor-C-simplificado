void func(int value){
  write(value);
  return ;
}

int main(){
  string str;
  int var;
  int a;
  int b;

  var = 8;
  str = "asdf";

  if(var >= 3){
    // str = "this is another string with interpolation #{a + (b * var)}";
  }
  else{
    var = 1;
  }

  // this is a comment

  while(var < 10){
    func(var);
    var = var + 1;
  }

  return 0;
}