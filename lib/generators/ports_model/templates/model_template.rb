class <%= file_name.classify %>PortTemplate < Porterable::Template

  set_map(
  <%= file_name.classify.constantize.columns.map{|c| "['#{c.name}','#{c.name}']"}.join(",\n") %>
  )
end
