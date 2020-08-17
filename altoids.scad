tol = 0.001;

// bounding boxes of tin sections
base = [94, 59, 13.5];  // portion visible below lip
lid = [94.5, 60, 7.5];  // height includes lip
lip = [96.5, 62, 1];
tin = [lip[0], lip[1], base[2]+lid[2]];
corner = 12;  // lip is 1mm more

module tin_slab(size, corner=corner) {
    x = size[0];
    y = size[1];
    z = size[2];
    translate([0, 0, z/2]) hull() {
            cube([x, y-2*corner, z], center=true);
            cube([x-2*corner, y, z], center=true);
            for (flip=[[1, 1], [1, -1], [-1, 1], [-1, -1]])
                translate([flip[0] * (x/2-corner), flip[1] * (y/2-corner)])
                    cylinder(r=corner, h=z, center=true);
    }
}

module tin_hull() {
    tin_slab([base[0], base[1], tin[2]]);  // bottom
    translate([0, 0, base[2]]) tin_slab(lid);  // top
    translate([0, 0, base[2]]) tin_slab(lip);  // lip
}

nozzle = 0.4;
width = 4*25.4;
wing = width/2 - base[0]/2;
sweep = corner * cos(asin(1-wing/corner));
shelf = [width-2, base[1]/2 + tin[1]/2, 1.6];
rail = [1.5*nozzle, shelf[1]-corner-sweep, nozzle];
rack = [width, 2+tin[1]/2+base[1]/2-corner-sweep, tin[2] + shelf[2] + 2];

module rack_shelf() {
    // main shelf
    difference() {
        union() {
            tin_slab([base[0], base[1], 1.6]);
            // rails
            translate([-shelf[0]/2, -tin[1]/2, 0])
                cube([shelf[0], rail[1], shelf[2]]);
        }
        translate([-shelf[0]/2+rail[0], -tin[1]/2-tol, rail[2]-shelf[2]])
            cube([shelf[0]-2*rail[0], rail[1]+tol, shelf[2]]);
    }
    // wings
    difference() {
        translate([-rack[0]/2, base[1]/2-corner-sweep, 0])
            cube([rack[0], sweep, shelf[2]]);
        for (flip=[0, 1]) mirror([flip, 0])
            translate([base[0]/2+corner, base[1]/2-corner, -shelf[2]])
                cylinder(r=corner, h=3*shelf[2]);
    }
    // back support rail
    translate([-shelf[0]/2, -tin[1]/2-1, rail[2]])
        cube([shelf[0], 2, shelf[2]-rail[2]]);
}

module rack_rounder(size, rounded=true) {
    x = min(size[0], size[1]);
    y = max(size[0], size[1]);
    z = size[2];
    mirror(size[1] < size[0] ? [-1, 1, 0] : [0, 0, 0]) hull() {
        cube([x, x, z]);
        cube([x, y-corner, z]);
        cube([x, y, z-corner]);
        translate([0, y-corner, z-corner]) intersection() {
            if (rounded) rotate([0, 90, 0]) cylinder(r=corner, h=x);
            cube([x, corner, corner]);
        }
    }
}

module rack_wall(tiers=5, rounded=true, flip=false, debug=false) {
    lift = (rack[2]-1) * (tiers-1);
    if (1 < tiers) {
        rack_wall(tiers-1, rounded=false, flip=flip, debug=debug);
    }
    wall = rack[0]/2 - tin[0]/2 - 1/2;
    scale([flip ? -1 : 1, 1, 1]) {
        // side
        difference() {
            translate([-rack[0]/2, -tin[1]/2-2, lift])
                rack_rounder([wall, rack[1], rack[2]], rounded=rounded);
            translate([-rack[0]/2+0.9, -tin[1]/2-3, lift+1.9])
                cube([rail[0]+0.2, rack[1]+2, shelf[2]+0.2]);
            translate([-rack[0]/2+0.9, -tin[1]/2-3, lift+nozzle+1.9])
                cube([wall, rack[1]+2, shelf[2]-nozzle+0.2]);
        }
        // back
        difference() {
            translate([-rack[0]/2, -tin[1]/2-2, lift])
                rack_rounder([3/16*rack[0], 2, rack[2]], rounded=rounded);
            translate([-rack[0]/2+0.9, -tin[1]/2-1.1, lift+rail[2]+1.9])
                cube([rack[0]-1.8, 1.1, shelf[2]-rail[2]+0.2]);
        }
        // show in context
        if (debug) {
            %translate([0, 0, lift+2]) rack_shelf();
            %translate([0, 0, lift+3.6]) tin_hull();
        }
    }
}

$fa = 12;
$fs = 0.1;
*rack_shelf();
left = true;
rack_wall(debug=true, flip=left);
%rack_wall(flip=!left);
