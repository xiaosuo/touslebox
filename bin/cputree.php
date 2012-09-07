#!/usr/bin/env php
<?php
#
# Copyright (C) 2012-  Changli Gao <xiaosuo@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

$path = "/sys/devices/system/cpu";
chdir($path);
$packages = Array();
$cnt = 0;
foreach (scandir(".") as $cpu) {
	if (preg_match("/^cpu[0-9]+$/", $cpu) == 0)
		continue;
	++$cnt;
        chdir("$cpu/topology");
        $package_id = intval(file_get_contents("physical_package_id"));
        $core_id = intval(file_get_contents("core_id"));
        $packages[$package_id][$core_id][] = intval(substr($cpu, 3));
        chdir("../../");
}

echo "cpus(" . $cnt . ")\n";

function print_tree($prefix, $tree) {
        $cnt = 0;
        foreach ($tree as $branch_id => $branch) {
                $cnt++;
                if (!is_array($branch))
                        $branch_id = $branch;
                if ($cnt == count($tree)) {
                        echo $prefix . "`-$branch_id\n";
                        $branch_prefix = $prefix . "  ";
                } else {
                        echo $prefix . "+-$branch_id\n";
                        $branch_prefix = $prefix . "| ";
                }
                if (is_array($branch))
                        print_tree($branch_prefix, $branch);
        }
}

print_tree("", $packages);
?>
