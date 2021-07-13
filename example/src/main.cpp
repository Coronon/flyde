#include <iostream>

#include "Calculator.hpp"

using namespace model;

int main (int argc, char *argv[]) { 
    std::cout << "Hi, if you can read this, you successfully compiled the example app!" << std::endl;
    std::cout << "Let's check out the advanced calculator program." << "\n" << std::endl;

    std::cout << "8 + 7 = " << Calculator::add(8, 7) << std::endl;
    std::cout << "8 * 7 = " << Calculator::mult(8, 7) << std::endl;
    std::cout << "8 - 7 = " << Calculator::sub(8, 7) << std::endl;
}
