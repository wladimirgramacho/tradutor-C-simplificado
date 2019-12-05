float func(int value){
  write(value);
}

int main(){
  string str;
  int var;
  int a;
  int b;

  a = 4;
  b = 2;
  var = 8;
  str = "asdf #{a} bbbb";
  write(str);

  if(var >= 3){
    str = "4 + (2 * 8) = #{a + (b * var)} !";
    write(str);
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