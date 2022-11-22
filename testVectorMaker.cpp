#include <vector>
#include <fstream>
#include <iostream>

using namespace std;


string toBinary(int num, int bits){
    return "";
}



//x[9:0] _ y[9:0] _ top[9:0] _ bottom[9:0] _ left[9:0] _ right[9:0] _ letterSelect[4:0] _ pixel[0:0]

int main(){

    int top, bot, left, right;
    int letterSelect;
    bool pixel;

    string temp;

    vector <vector <char> > bitmap;
    vector <char> line;

    //read in the vector from input file
    ifstream inFile;
    ofstream outFile;
    inFile.open("CharRom.txt");
    outFile.open("CharRomTestVectors.txt");

    for(int i = 0; !inFile.eof(); i++){
        getline(inFile, temp);
        for(int j = 0; j < temp.length(); j++){
            line.push_back(temp[j]);
        }
        bitmap.push_back(line);
    }

    for(int x = 0; x < 25; x++){
        for(int y = 0; y < 20; y++){

        if(/*x and y are in the rectangle bounds*/){
            if(bitmap[x][y] == '1')    pixel = 1;
            else                pixel = 0;
        }
        else{
            pixel = 0;
        }

            outFile << toBinary(x,10) << "_" << toBinary(y,10) << "_" << toBinary(top,10) << "_" 
                    << toBinary(bot,10) << "_" << toBinary(left,10) << "_" << toBinary(right,10) 
                    << "_" << toBinary(letterSelect,10) << "_" << pixel << "\n";
        }
    }
}
