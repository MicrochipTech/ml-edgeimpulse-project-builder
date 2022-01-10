/*******************************************************************************
  Main Source File

  Company:
    Microchip Technology Inc.

  File Name:
    main.c

  Summary:
    This file contains the "main" function for a project.

  Description:
    This file contains the "main" function for a project.  The
    "main" function calls the "SYS_Initialize" function to initialize the state
    machines of all modules in the system
 *******************************************************************************/

// *****************************************************************************
// *****************************************************************************
// Section: Included Files
// *****************************************************************************
// *****************************************************************************

#include <cstdint>
#include <cstdlib>                     // Defines EXIT_FAILURE
#include <cstdbool>                    // Defines true
#include "edge-impulse-sdk/porting/ei_classifier_porting.h"
#include "edge-impulse-sdk/classifier/ei_run_classifier.h"
#include "edge-impulse-sdk/dsp/numpy.hpp"
#include "model-parameters/model_metadata.h"

// *****************************************************************************
// *****************************************************************************
// Section: Edge impulse stub definitions
// *****************************************************************************
// *****************************************************************************

EI_IMPULSE_ERROR ei_sleep(int32_t us) {
    /* Optional: implement sleep */
    return EI_IMPULSE_OK;
}

uint64_t ei_read_timer_ms() {
    /* Optional: implement ms timer */
    return 0;
}

uint64_t ei_read_timer_us() {
    /* Optional: implement us timer */
    return 0;
}

extern "C" int get_feature_data(size_t offset, size_t length, float *out_ptr) {
    /* Implement signal data retrieval routine
    *
    *  Note: An alternative to implementing this function is to pass a buffer to
    *  edge impulse directly
    */
    return EI_IMPULSE_OK;
}

// *****************************************************************************
// *****************************************************************************
// Section: Main Entry Point
// *****************************************************************************
// *****************************************************************************

int main ( void )
{
    run_classifier_init();

    while ( true )
    {
        /* Define the input data */
        ei::signal_t signal;

        // Option 1: Pass an existing buffer
        float raw_features[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE];
        numpy::signal_from_buffer(&raw_features[0], EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, &signal);

        // Option 2: Use a callback to retrieve data
        // signal.total_length = EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE;
        // signal.get_data = &get_feature_data;

        /* Make inference */
        ei_impulse_result_t result;
        EI_IMPULSE_ERROR ei_status = run_classifier(&signal, &result, false);
        if (ei_status != EI_IMPULSE_OK) {
            // printf("run_classifier returned: %d\n", ei_status);
            break;
        }

        /* Print results */
        // printf("Predictions (DSP: %d ms., Classification: %d ms., Anomaly: %d ms.): \n",
        //     result.timing.dsp, result.timing.classification, result.timing.anomaly);
        // for (size_t ix = 0; ix < EI_CLASSIFIER_LABEL_COUNT; ix++) {
        //     printf("    %s: %f\n", result.classification[ix].label, result.classification[ix].value);
        // }
    }

    /* Execution should not come here during normal operation */

    return EXIT_FAILURE;
}


/*******************************************************************************
 End of File
*/

