package axis_pkg;

    parameter int data_width = 64;
    parameter int data_user  = 128;

    typedef logic [data_width-1:0] axis_data_t;

    typedef struct packed {
        axis_data_t               tdata;
        logic [data_width/8-1:0]  tkeep; // one bit per byte
        logic                     tlast;
        logic [data_user-1:0]     tuser;
    } axis_word_t;

endpackage : axis_pkg