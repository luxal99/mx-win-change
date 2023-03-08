#include <stdlib.h>
#include <stdio.h>

void mouseWatcher(void);
int main(){
mouseWatcher();
}

void mouseWatcher(void){
while(1){
system("cnee --record --mouse | awk '/7,5,0,0,1/'" );
}
}