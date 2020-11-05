module top (
    input i_clk,

    output o_ftdi_clk,
    output o_ftdi_si,
    input i_ftdi_so,
    input i_ftdi_cts,

    input i_n64_nmi,
    input i_n64_reset,

    input i_n64_pi_alel,
    input i_n64_pi_aleh,
    input i_n64_pi_read,
    input i_n64_pi_write,
    inout [15:0] io_n64_pi_ad,

    input i_n64_si_clk,
    inout io_n64_si_dq,

    input i_n64_cic_clk,
    inout io_n64_cic_dq,

    output o_sdram_clk,
    output o_sdram_cs,
    output o_sdram_ras,
    output o_sdram_cas,
    output o_sdram_we,
    output [1:0] o_sdram_ba,
    output [12:0] o_sdram_a,
    inout [15:0] io_sdram_dq,

    output o_sd_clk,
    inout io_sd_cmd,
    inout [3:0] io_sd_dat,

    output o_flash_clk,
    output o_flash_cs,
    inout [3:0] io_flash_dq,

    output o_sram_clk,
    output o_sram_cs,
    inout [3:0] io_sram_dq,

    output o_rtc_scl,
    inout io_rtc_sda,

    output o_led,

    inout [7:0] io_pmod
);

    // Clock and reset signals

    wire w_sys_clk;
    wire w_sdram_clk;
    wire w_pll_lock;
    wire w_sys_reset = ~w_pll_lock;


    // PLL clock generator

    pll sys_pll (
        .inclk0(i_clk),
        .c0(w_sys_clk),
        .c1(w_sdram_clk),
        .locked(w_pll_lock)
    );


    // SDRAM clock output

    gpio_ddro sdram_clk_ddro (
        .outclock(w_sdram_clk),
        .outclocken(1'b1),
        .din({1'b0, 1'b1}),
        .pad_out(o_sdram_clk)
    );


    // Bank ids

    localparam [3:0] BANK_INVALID   = 4'd0;
    localparam [3:0] BANK_ROM       = 4'd1;
    localparam [3:0] BANK_CART      = 4'd2;
    localparam [3:0] BANK_EEPROM    = 4'd3;


    // N64 PI

    wire w_n64_request;
    wire w_n64_write;
    wire w_n64_busy;
    wire w_n64_ack;
    wire [3:0] w_n64_bank;
    wire [25:0] w_n64_address;
    wire [31:0] w_n64_i_data;
    wire [31:0] w_n64_o_data;

    wire w_n64_busy_cart_control;
    wire w_n64_ack_cart_control;
    wire [31:0] w_n64_i_data_cart_control;

    wire w_n64_busy_sdram;
    wire w_n64_ack_sdram;
    wire [31:0] w_n64_i_data_sdram;

    wire w_n64_busy_embedded_flash;
    wire w_n64_ack_embedded_flash;
    wire [31:0] w_n64_i_data_embedded_flash;

    wire w_n64_busy_eeprom;
    wire w_n64_ack_eeprom;
    wire [31:0] w_n64_i_data_eeprom;

    always @(*) begin
        w_n64_busy = w_n64_busy_cart_control || w_n64_busy_sdram || w_n64_busy_embedded_flash || w_n64_busy_eeprom;
        w_n64_ack = w_n64_ack_cart_control || w_n64_ack_sdram || w_n64_ack_embedded_flash || w_n64_ack_eeprom;
        w_n64_i_data = 32'h0000_0000;
        if (w_n64_ack_cart_control) w_n64_i_data = w_n64_i_data_cart_control;
        if (w_n64_ack_sdram) w_n64_i_data = w_n64_i_data_sdram;
        if (w_n64_ack_embedded_flash) w_n64_i_data = w_n64_i_data_embedded_flash;
        if (w_n64_ack_eeprom) w_n64_i_data = w_n64_i_data_eeprom;
    end

    n64_pi n64_pi_inst (
        .i_clk(w_sys_clk),
        .i_reset(w_sys_reset),

        .i_n64_reset(i_n64_reset),
        .i_n64_pi_alel(i_n64_pi_alel),
        .i_n64_pi_aleh(i_n64_pi_aleh),
        .i_n64_pi_read(i_n64_pi_read),
        .i_n64_pi_write(i_n64_pi_write),
        .io_n64_pi_ad(io_n64_pi_ad),

        .o_request(w_n64_request),
        .o_write(w_n64_write),
        .i_busy(w_n64_busy),
        .i_ack(w_n64_ack),
        .o_bank(w_n64_bank),
        .o_address(w_n64_address),
        .i_data(w_n64_i_data),
        .o_data(w_n64_o_data)
    );


    // PC USB

    wire w_pc_request;
    wire w_pc_write;
    wire w_pc_busy;
    wire w_pc_ack;
    wire [3:0] w_pc_bank;
    wire [25:0] w_pc_address;
    wire [31:0] w_pc_i_data;
    wire [31:0] w_pc_o_data;

    wire w_pc_busy_cart_control;
    wire w_pc_ack_cart_control;
    wire [31:0] w_pc_i_data_cart_control;

    wire w_pc_busy_sdram;
    wire w_pc_ack_sdram;
    wire [31:0] w_pc_i_data_sdram;

    wire w_pc_busy_eeprom;
    wire w_pc_ack_eeprom;
    wire [31:0] w_pc_i_data_eeprom;

    always @(*) begin
        w_pc_busy = w_pc_busy_cart_control || w_pc_busy_sdram || w_pc_busy_eeprom;
        w_pc_ack = w_pc_ack_cart_control || w_pc_ack_sdram || w_pc_ack_eeprom;
        w_pc_i_data = 32'h0000_0000;
        if (w_pc_ack_cart_control) w_pc_i_data = w_pc_i_data_cart_control;
        if (w_pc_ack_sdram) w_pc_i_data = w_pc_i_data_sdram;
        if (w_pc_ack_eeprom) w_pc_i_data = w_pc_i_data_eeprom;
    end

    usb_pc usb_pc_inst (
        .i_clk(w_sys_clk),
        .i_reset(w_sys_reset),

        .o_ftdi_clk(o_ftdi_clk),
        .o_ftdi_si(o_ftdi_si),
        .i_ftdi_so(i_ftdi_so),
        .i_ftdi_cts(i_ftdi_cts),

        .o_request(w_pc_request),
        .o_write(w_pc_write),
        .i_busy(w_pc_busy),
        .i_ack(w_pc_ack),
        .o_bank(w_pc_bank),
        .o_address(w_pc_address),
        .i_data(w_pc_i_data),
        .o_data(w_pc_o_data)
    );


    // Cart interface

    wire w_cart_control_request;
    wire w_cart_control_write;
    wire w_cart_control_busy;
    wire w_cart_control_ack;
    wire [25:0] w_cart_control_address;
    wire [31:0] w_cart_control_o_data;
    wire [31:0] w_cart_control_i_data;

    wire w_rom_switch;
    wire w_eeprom_enable;
    wire w_eeprom_16k_mode;

    device_arbiter device_arbiter_cart_control_inst (
        .i_clk(w_sys_clk),
        .i_reset(w_sys_reset),
        
        .i_request_pri(w_n64_request),
        .i_write_pri(w_n64_write),
        .o_busy_pri(w_n64_busy_cart_control),
        .o_ack_pri(w_n64_ack_cart_control),
        .i_bank_pri(w_n64_bank),
        .i_address_pri(w_n64_address[25:2]),
        .o_data_pri(w_n64_i_data_cart_control),
        .i_data_pri(w_n64_o_data),
    
        .i_request_sec(w_pc_request),
        .i_write_sec(w_pc_write),
        .o_busy_sec(w_pc_busy_cart_control),
        .o_ack_sec(w_pc_ack_cart_control),
        .i_bank_sec(w_pc_bank),
        .i_address_sec(w_pc_address[25:2]),
        .o_data_sec(w_pc_i_data_cart_control),
        .i_data_sec(w_pc_o_data),
    
        .o_request(w_cart_control_request),
        .o_write(w_cart_control_write),
        .i_busy(w_cart_control_busy),
        .i_ack(w_cart_control_ack),
        .o_address(w_cart_control_address),
        .i_data(w_cart_control_o_data),
        .o_data(w_cart_control_i_data)
    );
    defparam device_arbiter_cart_control_inst.DEVICE_BANK = BANK_CART;

    cart_control cart_control_inst (
        .i_clk(w_sys_clk),
        .i_reset(w_sys_reset),

        .i_n64_reset(i_n64_reset),
        .i_n64_nmi(i_n64_nmi),

        .i_request(w_cart_control_request),
        .i_write(w_cart_control_write),
        .o_busy(w_cart_control_busy),
        .o_ack(w_cart_control_ack),
        .i_address(w_cart_control_address),
        .o_data(w_cart_control_o_data),
        .i_data(w_cart_control_i_data),
    
        .o_rom_switch(w_rom_switch),
        .o_eeprom_enable(w_eeprom_enable),
        .o_eeprom_16k_mode(w_eeprom_16k_mode)
    );


    // Embedded flash

    memory_embedded_flash memory_embedded_flash_inst (
        .i_clk(w_sys_clk),
        .i_reset(w_sys_reset),

        .i_request(!w_rom_switch && w_n64_request && !w_n64_write && w_n64_bank == BANK_ROM),
        .o_busy(w_n64_busy_embedded_flash),
        .o_ack(w_n64_ack_embedded_flash),
        .i_address(w_n64_address[25:2]),
        .o_data(w_n64_i_data_embedded_flash)
    );


    // SDRAM

    wire w_sdram_request;
    wire w_sdram_write;
    wire w_sdram_busy;
    wire w_sdram_ack;
    wire [25:0] w_sdram_address;
    wire [31:0] w_sdram_o_data;
    wire [31:0] w_sdram_i_data;

    device_arbiter device_arbiter_sdram_inst (
        .i_clk(w_sys_clk),
        .i_reset(w_sys_reset),
        
        .i_request_pri(w_rom_switch && w_n64_request),
        .i_write_pri(w_n64_write),
        .o_busy_pri(w_n64_busy_sdram),
        .o_ack_pri(w_n64_ack_sdram),
        .i_bank_pri(w_n64_bank),
        .i_address_pri(w_n64_address[25:1]),
        .o_data_pri(w_n64_i_data_sdram),
        .i_data_pri(w_n64_o_data),
    
        .i_request_sec(w_pc_request),
        .i_write_sec(w_pc_write),
        .o_busy_sec(w_pc_busy_sdram),
        .o_ack_sec(w_pc_ack_sdram),
        .i_bank_sec(w_pc_bank),
        .i_address_sec(w_pc_address[25:1]),
        .o_data_sec(w_pc_i_data_sdram),
        .i_data_sec(w_pc_o_data),
    
        .o_request(w_sdram_request),
        .o_write(w_sdram_write),
        .i_busy(w_sdram_busy),
        .i_ack(w_sdram_ack),
        .o_address(w_sdram_address),
        .i_data(w_sdram_o_data),
        .o_data(w_sdram_i_data)
    );
    defparam device_arbiter_sdram_inst.DEVICE_BANK = BANK_ROM;

    memory_sdram memory_sdram_inst (
        .i_clk(w_sys_clk),
        .i_reset(w_sys_reset),

        .o_sdram_cs(o_sdram_cs),
        .o_sdram_ras(o_sdram_ras),
        .o_sdram_cas(o_sdram_cas),
        .o_sdram_we(o_sdram_we),
        .o_sdram_ba(o_sdram_ba),
        .o_sdram_a(o_sdram_a),
        .io_sdram_dq(io_sdram_dq),

        .i_request(w_sdram_request),
        .i_write(w_sdram_write),
        .o_busy(w_sdram_busy),
        .o_ack(w_sdram_ack),
        .i_address(w_sdram_address),
        .o_data(w_sdram_o_data),
        .i_data(w_sdram_i_data)
    );


    // EEPROM 4/16k

    wire w_eeprom_request;
    wire w_eeprom_write;
    wire w_eeprom_busy;
    wire w_eeprom_ack;
    wire [25:0] w_eeprom_address;
    wire [31:0] w_eeprom_o_data;
    wire [31:0] w_eeprom_i_data;

    device_arbiter device_arbiter_eeprom_inst (
        .i_clk(w_sys_clk),
        .i_reset(w_sys_reset),
        
        .i_request_pri(w_n64_request),
        .i_write_pri(w_n64_write),
        .o_busy_pri(w_n64_busy_eeprom),
        .o_ack_pri(w_n64_ack_eeprom),
        .i_bank_pri(w_n64_bank),
        .i_address_pri(w_n64_address[25:2]),
        .o_data_pri(w_n64_i_data_eeprom),
        .i_data_pri(w_n64_o_data),
    
        .i_request_sec(w_pc_request),
        .i_write_sec(w_pc_write),
        .o_busy_sec(w_pc_busy_eeprom),
        .o_ack_sec(w_pc_ack_eeprom),
        .i_bank_sec(w_pc_bank),
        .i_address_sec(w_pc_address[25:2]),
        .o_data_sec(w_pc_i_data_eeprom),
        .i_data_sec(w_pc_o_data),
    
        .o_request(w_eeprom_request),
        .o_write(w_eeprom_write),
        .i_busy(w_eeprom_busy),
        .i_ack(w_eeprom_ack),
        .o_address(w_eeprom_address),
        .i_data(w_eeprom_o_data),
        .o_data(w_eeprom_i_data)
    );
    defparam device_arbiter_eeprom_inst.DEVICE_BANK = BANK_EEPROM;

    n64_si n64_si_inst (
        .i_clk(w_sys_clk),
        .i_reset(w_sys_reset),

        .i_n64_reset(i_n64_reset),
        .i_n64_si_clk(i_n64_si_clk),
        .io_n64_si_dq(io_n64_si_dq),

        .i_request(w_eeprom_request),
        .i_write(w_eeprom_write),
        .o_busy(w_eeprom_busy),
        .o_ack(w_eeprom_ack),
        .i_address(w_eeprom_address),
        .i_data(w_eeprom_i_data),
        .o_data(w_eeprom_o_data),

        .i_eeprom_enable(w_eeprom_enable),
        .i_eeprom_16k_mode(w_eeprom_16k_mode)
    );

endmodule
