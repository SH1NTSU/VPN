const std = @import("std");

pub const server_errors = error{
    
};

pub const parser_errors = error{
    WrongStructure,
    InvalidIp,
    InvalidPort,
    
};


pub const crypto_errors = error {
    
};

pub const session_errors = error{
    CantLogIn,
    CantLogOut,
};

