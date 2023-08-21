// Project: Color Blind Easy Color Name
// Author:  Joao Carvalho
// Date:    2023.08.20
//
// Description: A simple project that given a color code in hexadecimal String,
//              this project is made with the Odin programming language.
//
//              $ ./color_blind_easy_color_name d3c2a5
//                Slightly Dark Orangish White
//
//              or 
//
//              $ ./color_blind_easy_color_name D3C2A5
//                Slightly Dark Orangish White
//
//              gives back a description of the color has a string. The
//              description is perceptually good for a color blind person.
//              The majority of color blind persons don't see only black and
//              white color, or gray shades, but normally they are more sensible
//              to one color then the others.
//
//              The reason why I did this small program is:
//              In the world population 8% of men and 0.5% of women are color
//              blind. This is roughly 300 million men and 19 million women.
//              There should exist free programs to assist them.
//
//              Also there are many different methods to do a color picker
//              depending on the operating system you are (Windows, Linux or
//              Mac) and depending, for example in Linux if you have a X or
//              Wayland windows system.
//              Many of the possible solution work with a shell script and you
//              can simply pipe it to this program and redirect the output.
//              This is a fast executing program.
//
//              The color text descriptions where extracted and reformated from
//              a section from the free accessible file 
//              https://www.hikarun.com/e/color-fr.xml
//              There you can find a free windows program for color blind persons.
//              See my formatted file for details.
// 
// License: The license of the my formatted description file is the license from
//          it's original author that is available in the link above.
//          The license of my source code is MIT Open Source License.  
//  


package main

import "core:fmt"
import "core:os"
import "core:c/libc"
import "core:strconv"
import "core:math"
import "core:strings"

EXIT_FAILURE :: 1
EXIT_SUCESS  :: 0


main :: proc () {
    if len(os.args) != 2 {
        fmt.println("Error:\n  Please pass the color argument in RGG Hex format \n   ex: color_blind_easy_color_name F2C3A4")
        os.exit( EXIT_FAILURE )
    }

    color_hex_str : ^string = & os.args[1];
    imported_color_description := #load("color_blind_easy_color_names.txt");
    color_descript_str := strings.string_from_ptr(&imported_color_description[0], len(imported_color_description) )

    color_vec: [dynamic]Color = parse_color_descriptions(color_descript_str )
    defer delete( color_vec )
    nearest_color_description, err, ok := search_nearest_color(color_vec, color_hex_str^)
    if !ok {
        fmt.println("Error: %v", err.msg)
        fmt.println("Error: \n In hex format string \n ex: color_blind_easy_color_name F2C3A4 ")
        os.exit(EXIT_FAILURE)
    }
    fmt.printf("%v\n", nearest_color_description)
}

Color :: struct {
    red:   u8,
    green: u8,
    blue:  u8,
    text_description: string,
}

color_new :: proc ( red: u8, green: u8, blue: u8, text_description: string ) -> Color {
    return Color {
        red,
        green,
        blue,
        text_description,
    }
}

/// Calculate the Euclidean distance:
///    Sqrt( (a0 - b0)^2 + (a1 - b1)^2 + (a2 - b2)^2 ).
/// 
/// There are specific methods to compare perceptual color distances.
/// But because we have 912 samples the color will be very close even 
/// with a Euclidean distance.
calc_distance :: proc ( color: ^Color, red: u8, green: u8, blue: u8 ) -> f32 {
    f32_powf :: libc.powf
    f32_sqrt :: libc.sqrtf

    sum_of_square_diff :=  (f32_powf(  f32(color.red) - f32(red), 2 )                 
                          + f32_powf( f32(color.green) - f32(green), 2 )   
                          + f32_powf( f32(color.blue) - f32(blue), 2 ) )
    return f32( f32_sqrt(sum_of_square_diff) )
}

parse_color_descriptions :: proc ( color_descript_str: string ) -> [dynamic]Color {

    color_vec : [dynamic]Color = make([dynamic]Color, 0, 1000)

    for line in strings.split_lines( color_descript_str ) {
        // Remove empty lines and comment lines, that start with a "#" symbol.
        line_len := len(line)
        if (    line_len == 0 
            || (line_len > 0 && line[0 : 1] == "#")
            || len(strings.trim(line, " \t")) == 0 ) {
            continue
        }

        splitted_line := strings.split(line, " ");
        if len(splitted_line) < 3 {
            fmt.printf("Error: Invalid line: %v\n", line)
            continue
        }        
    
        hex_str := splitted_line[1]

        red_tmp, ok := strconv.parse_uint( hex_str[ 0 : 2 ], base = 16 )
        // if !ok {
        //     fmt.printf("Error: Invalid line: %v\n", line)
        //     continue
        // }
        red := u8(red_tmp)
        green_tmp, _ := strconv.parse_uint( hex_str[ 2 : 4 ], base = 16 )
        green := u8( green_tmp ) 
        blue_tmp, _ := strconv.parse_uint( hex_str[ 4 : 6 ], base = 16 )
        blue  := u8( blue_tmp )
        text_description := strings.trim( strings.join( splitted_line[2 : ], " " ), " \t" )
        cur_color := color_new(red, green, blue, text_description)
        append( & color_vec, cur_color )
    }

    return color_vec
}

Error :: struct {
    msg: string,
}

search_nearest_color :: proc ( color_vec: [dynamic]Color, hex_color_str: string ) -> ( string, Error, bool ) {
    
    // Parse the input safely.
    hex_color_str := strings.trim( hex_color_str, " \t" ) 
    if len( hex_color_str ) != 6 {
        err := Error{ "Invalid hex color string size must be 6 digits!" }
        return "", err, false
    }
    res, ok := strconv.parse_uint( hex_color_str[ 0 : 2 ], base = 16 ) 
    if !ok {
        err := Error{ "Invalid hex color string, invalid red component!" }
        return "", err, false 
    }
    red := u8(res)
    
    res, ok = strconv.parse_uint( hex_color_str[ 2 : 4 ], base = 16 )
    if !ok {
        err := Error{ "Invalid hex color string, invalid green component!" }
        return "", err, false 
    }
    green := u8(res)

    res, ok = strconv.parse_uint( hex_color_str[ 4 : 6 ], base = 16 )
        if !ok {
            err := Error{ "Invalid hex color string, invalid blue component!" }
            return "", err, false
        }
    blue := u8(res)

    // TODO: Implement a better algorithm that doesn't do this by brute force.

    // Search for the best and nearest correspondence in 3 degrees of colors.        
    nearest_distance : f32= math.F32_MAX 
    cur_nearest_color: Color = color_vec[0]
    for cur_color, index in color_vec {
        distance := calc_distance( & color_vec[index], red, green, blue )
        if nearest_distance > distance {
            nearest_distance = distance
            cur_nearest_color = cur_color
        }
    }

    return cur_nearest_color.text_description, Error{""}, true
}

