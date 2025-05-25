// Principal parameters
box_length = 90;
box_width = 90;
box_height = 40;
wall_thickness = 2;
tube_length = 30;
tilt_angle = 60;

// --- Sensors ---

module cylinder_photo() {
    difference(){
        cylinder(h=tube_length, r=7, center=false, $fn=100); 
        
        translate([0, 0, tube_length-wall_thickness])
        cylinder(h=6*wall_thickness, r=5, center=false, $fn=100);
        
        translate([-3.5/2, -3, -0.5])
        cube([3.5, 6, tube_length]);
    }
}

//cylinder_photo();

module cylinder_dht() {
    difference(){
        cylinder(h=tube_length, r=12, center=false, $fn=100); 
        
        translate([-11/2, -17/2, tube_length-5])
        cube([11, 17, 17]);
        
        translate([-11/2, -14.5/2, -0.5])
        cube([9, 14.5, tube_length]);
    }
}

//cylinder_dht();

// --- Box ---
module fulled_totem () {
    union() {
        cube([box_length, box_width, box_height]);

        translate([box_length-6*wall_thickness, 7, box_height/2-2])
        rotate([0, tilt_angle, -90])
        cylinder_photo();

        translate([8*wall_thickness, 7, box_height/2-2])
        rotate([0, tilt_angle, -90])
        cylinder_dht();
    }
};

//fulled_totem();

module totem_mkr () {
    difference() {
        union() {
            difference() {
                fulled_totem();
        
                translate([wall_thickness, wall_thickness, wall_thickness])
                cube([box_length-2*wall_thickness, box_width-2*wall_thickness, box_height]);
            }
        
            cube([box_length, 2*wall_thickness, box_height-wall_thickness-0.5]);
        
            cube([2*wall_thickness, box_width, box_height-wall_thickness-0.5]);
        
            translate([0, box_width-2*wall_thickness, 0])
            cube([box_length, 2*wall_thickness, box_height-wall_thickness-0.5]);
        
            translate([box_length-2*wall_thickness, 0, 0])
            cube([2*wall_thickness, box_width, box_height-wall_thickness-0.5]);
        
            translate([4, 4, 0])
            cylinder(h=box_height-wall_thickness-0.5, r=4, center=false, $fn=100);
        
            translate([box_length-4, 4, 0])
            cylinder(h=box_height-wall_thickness-0.5, r=4, center=false, $fn=100);
        
            translate([box_length-4, box_width-4, 0])
            cylinder(h=box_height-wall_thickness-0.5, r=4, center=false, $fn=100);
        
            translate([4, box_width-4, 0])
            cylinder(h=box_height-wall_thickness-0.5, r=4, center=false, $fn=100);
        }
        translate([4, 4, 2*wall_thickness])
        cylinder(h=box_height-wall_thickness, r=1, center=false, $fn=100);
        
        translate([box_length-4, 4, 2*wall_thickness])
        cylinder(h=box_height, r=1, center=false, $fn=100);
        
        translate([box_length-4, box_width-4, 2*wall_thickness])
        cylinder(h=box_height-wall_thickness, r=1, center=false, $fn=100);
        
        translate([4, box_width-4, 2*wall_thickness])
        cylinder(h=box_height, r=1, center=false, $fn=100);
    }
};

module totem_without_closing () {
    difference() {
        totem_mkr();
        
        translate([box_length-15.5, -1, box_height/2])
        cube([7, 4*wall_thickness, 3*wall_thickness]);
        
        translate([8.5, -1, box_height/2-2])
        cube([15, 4*wall_thickness, 13]);
        
        translate([box_length-2*wall_thickness-1, box_width/2-10, box_height/2-1])
        cube([10, 20, 14]);
    }
}

totem_without_closing();

// --- Totem ---
module totem () {
    difference() {
        totem_without_closing();
        
        translate([box_length-wall_thickness-1, wall_thickness, box_height-3*wall_thickness])
        cube([2*wall_thickness, box_width-2*wall_thickness, wall_thickness]);
        
        translate([-1, wall_thickness, box_height-3*wall_thickness])
        cube([2*wall_thickness, box_width-2*wall_thickness, wall_thickness]);
    }
}

//totem();


module cover_box () {
    difference() {        
        cube([box_length-2*wall_thickness-0.5, box_width-2*wall_thickness-0.5, wall_thickness]);
        
        translate([1.5, 1.5, -1])
        cylinder(h=box_height-wall_thickness, r=1, center=false, $fn=100);
        
        translate([box_length-2*wall_thickness-0.5-1.5, +1.5, -1])
        cylinder(h=box_height, r=1, center=false, $fn=100);
        
        translate([box_length-2*wall_thickness-0.5-1.5, box_width-2*wall_thickness-0.5-1.5, -1])
        cylinder(h=box_height-wall_thickness, r=1, center=false, $fn=100);
        
        translate([+1.5, box_width-2*wall_thickness-0.5-1.5, 0-1])
        cylinder(h=box_height, r=1, center=false, $fn=100);
    }
}

//translate([wall_thickness+0.5, wall_thickness+0.5, box_height-wall_thickness])
//cover_box();
