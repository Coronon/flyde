#include <iostream>

#include "Calculator.hpp"
#include "../include/constants/numbers.hpp"

using namespace model;

int main (int argc, char *argv[]) { 
    #ifdef PRINTHELLO
    std::cout << "HELLO" << std::endl;
    return 0;
    #endif 
    
    #ifdef PRINTBYE
    std::cout << "BYE" << std::endl;
    return 0;
    #endif

    std::cout << "Hi, if you can read this, you successfully compiled the example app!" << std::endl;
    std::cout << "Let's check out the advanced calculator program." << "\n" << std::endl;

    std::cout << "8 + 7 = " << Calculator::add(constants::eight, constants::seven) << std::endl;
    std::cout << "8 * 7 = " << Calculator::mult(constants::eight, constants::seven) << std::endl;
    std::cout << "8 - 7 = " << Calculator::sub(constants::eight, constants::seven) << std::endl;

    return 0;
}
