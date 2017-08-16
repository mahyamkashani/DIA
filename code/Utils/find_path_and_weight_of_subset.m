%--------------------------------------------------------------------------
function [semantic_path_cell_of_subset, weight_of_path_cell_of_subset] = ...
             find_path_and_weight_of_subset(subset, SH_and_SP_structure)
%--------------------------------------------------------------------------

% this function constructs the semantic path of a subset,
% according to the semantic path of all classes based on 
% semantic hierarchy and same meaning pair

% semantic path
semantic_path_structure = SH_and_SP_structure.semantic_path;
semantic_path_cell = semantic_path_structure.semantic_path_cell;
weight_of_path_cell = semantic_path_structure.weight_of_path_cell;
num_semantic_path = numel(semantic_path_cell);
index_of_same_meaning_pair = semantic_path_structure.index_of_same_meaning_pair_in_path;

% semantic hierarchy
semantic_hierarchy_structure = SH_and_SP_structure.semantic_hierarchy;
ancestor_cell = semantic_hierarchy_structure.ancestor_cell;
descendant_cell = semantic_hierarchy_structure.descendant_cell;
nodes_structure = semantic_hierarchy_structure.nodes_structure; 

% different types of class sets in the whole class vocabulary 
single_class_set = nodes_structure.single;
leaf_class_set = nodes_structure.leaf;
median_class_set = nodes_structure.median;
root_class_set = nodes_structure.root;

% different types of class sets in the class subset
single_class_in_subset = intersect(single_class_set, subset); 
leaf_class_in_subset = intersect(leaf_class_set, subset); 
median_class_in_subset = intersect(median_class_set, subset); 
root_class_in_subset = intersect(root_class_set, subset); 
%nonsingle_class_in_subset = setdiff(subset, single_class_in_subset); 

semantic_path_cell_of_subset = {}; 
weight_of_path_cell_of_subset = {};

%------------------------- find the path from each leaf class
for i = 1:numel(leaf_class_in_subset)
    ci = leaf_class_in_subset(i); 
    for j = 1:num_semantic_path
        path_j = semantic_path_cell{j};
        weight_of_path_j = weight_of_path_cell{j};
        if sum(path_j == ci) > 0
            semantic_path_cell_of_subset = [semantic_path_cell_of_subset, {path_j}];
            weight_of_path_cell_of_subset = [ ...
                weight_of_path_cell_of_subset, {weight_of_path_j}]; 
        end
    end
end

%------------------------- find the path from the remaining median path 
current_included_class = unique([semantic_path_cell_of_subset{:}]); 
remaining_median_class = setdiff(median_class_in_subset, ...
                         intersect(median_class_in_subset, ...
                         current_included_class)); 
if numel(remaining_median_class) > 0
    for i = 1:numel(remaining_median_class)
        ci = remaining_median_class(i); 
        child_of_ci_in_remaining_median = intersect(descendant_cell{ci}, ...
                                               remaining_median_class); 
        if isempty(child_of_ci_in_remaining_median)
            num_ancestor_of_ci = numel(ancestor_cell{ci});
            temp_count = num_ancestor_of_ci; 
            for j = 1:num_semantic_path
                if temp_count == 0
                    break;
                end
                path_j = semantic_path_cell{j};
                weight_of_path_j = weight_of_path_cell{j};
                location_ci = find(path_j == ci);
                if ~isempty(location_ci)
                    semantic_path_cell_of_subset = [semantic_path_cell_of_subset, ...
                                                    {path_j(location_ci:end)}];

                    weight_of_ci = weight_of_path_j(location_ci);
                    rate = 1/weight_of_ci;
                    weight_of_path_cell_of_subset = [ ...
                       weight_of_path_cell_of_subset, ...
                       {weight_of_path_j(location_ci:end) .* rate}]; 
                    temp_count = temp_count - 1;
                end
            end
        end
    end
end

%%------------------------- the remaining root class
current_included_class = unique([semantic_path_cell_of_subset{:}]); 
remaining_root_class = setdiff(root_class_in_subset, ...
                         intersect(root_class_in_subset, ...
                         current_included_class)); 
for i = 1:numel(remaining_root_class)
    ci = remaining_root_class(i); 
    semantic_path_cell_of_subset = ...
        [semantic_path_cell_of_subset, {ci}];
    weight_of_path_cell_of_subset = [ ...
        weight_of_path_cell_of_subset, {[1]}]; 
end
                     

%------------------------- find the same meaning pair in single class set
for i = 1:numel(single_class_in_subset)
    ci = single_class_in_subset(i);
    for j = index_of_same_meaning_pair % the range of same meaning pair  % 101:106 for espgame % 137:139 for iaprtc12
        pair_j = semantic_path_cell{j};
        c_j1 = pair_j(1); 
        c_j2 = pair_j(2);
        if ci == c_j1
            semantic_path_cell_of_subset = ...
                [semantic_path_cell_of_subset, {pair_j}];
            weight_of_path_cell_of_subset = [ ...
                weight_of_path_cell_of_subset, {[1 1]}]; 
            single_class_in_subset(single_class_in_subset==c_j1) = inf; 
            single_class_in_subset(single_class_in_subset==c_j2) = inf; 
        elseif ci == c_j2
            semantic_path_cell_of_subset = ...
                [semantic_path_cell_of_subset, {pair_j}];
            weight_of_path_cell_of_subset = [ ...
                weight_of_path_cell_of_subset, {[1 1]}];
            single_class_in_subset(single_class_in_subset==c_j1) = inf; 
            single_class_in_subset(single_class_in_subset==c_j2) = inf; 
        end
    end
end

%------------------------- the remaining single class
remaining_single_class = single_class_in_subset(single_class_in_subset ~= inf); 
for i = 1:numel(remaining_single_class)
    ci = remaining_single_class(i); 
    semantic_path_cell_of_subset = ...
        [semantic_path_cell_of_subset, {ci}];
    weight_of_path_cell_of_subset = [ ...
        weight_of_path_cell_of_subset, {[1]}]; 
end      

%------------------------ remove the repeat path
remove_index = []; 
for i = 1:numel(semantic_path_cell_of_subset)-1
    path_i = semantic_path_cell_of_subset{i};
    for j = i+1
        path_j = semantic_path_cell_of_subset{j};
        if ~isempty(intersect(path_i, path_j))
            if numel(path_i) < numel(path_j)
                temp_cell = arrayfun(@(x) ismember(x, path_j), path_i, 'UniformOutput', false);
                temp_vec = [temp_cell{:}];
                if sum(temp_vec)==numel(path_i)
                    remove_index = [remove_index, i];
                end
            else
                temp_cell = arrayfun(@(x) ismember(x, path_i), path_j, 'UniformOutput', false);
                temp_vec = [temp_cell{:}];
                if sum(temp_vec)==numel(path_j)
                    remove_index = [remove_index, j];
                end
            end
        end
    end
end
semantic_path_cell_of_subset(remove_index) = [];
weight_of_path_cell_of_subset(remove_index) = [];
 
end % of function