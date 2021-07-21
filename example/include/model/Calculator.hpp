#pragma once

namespace model {

    class Calculator {
        public: 
            /// Add two integers.
            static int add(int lhs, int rhs);

            /// Multiply two integers.
            static int mult(int lhs, int rhs);

            /// Substract `rhs` from `lhs`.
            static int sub(int lhs, int rhs);
    };

}
