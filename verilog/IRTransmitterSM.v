module IRTransmitterSM(
    //Standard Signals
    input       RESET,
    input       CLK,
    // Bus Interface Signals
    input [3:0] COMMAND,
    input       SEND_PACKET,
    // IF LED signal
    output      IR_LED
);

    /*
    Generate the pulse signal here from the main clock running at 50MHz to generate the right frequency for
    the car in question e.g. 40KHz for BLUE coded cars
    */

    /*
    ....................
    FILL IN THIS AREA
    ...................
    */

    /*
    Simple state machine to generate the states of the packet i.e. Start, Gaps, Right Assert or De-Assert, Left
    Assert or De-Assert, Backward Assert or De-Assert, and Forward Assert or De-Assert
    */

    /*
    ....................
    FILL IN THIS AREA
    ...................
    */

    // Finally, tie the pulse generator with the packet state to generate IR_LED

    /*
    ....................
    FILL IN THIS AREA
    ...................
    */

endmodule
