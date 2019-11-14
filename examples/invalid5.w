float fun(){
  float w;
  return w;
}

int main(){
  int var;
  float other_var;

  var = 3.14; // type mismatch
  var = 3.14 + 2.35; // type mismatch
  var = fun(); // type mismatch
  var = other_var; // type mismatch
  var = ""; // type mismatch

  a(); // function not declared
}

int a(){
  return;
}