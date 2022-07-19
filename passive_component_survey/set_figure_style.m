function set_figure_style(scale)

    if nargin <1
        scale = 2;
    end
    
    % Note: by setting the interpreter to 'latex', MATLAB ignores the
    % 'FontName', 'FontWeight', and 'FontAngle' properties.
    
    % All other text on figure
    set(findall(gcf,'type','text'),'FontName','TimesNewRoman','Interpreter','latex')	% all fonts in the figure
    set(findall(gcf,'type','text'),'FontSize',8*scale)   
    
    % legend 
    l = findobj(gcf,'Tag','legend');
    set(l,'FontSize',8*scale,'FontName','TimesNewRoman','Interpreter','latex') 

    % Change line width
%     h = findobj(gcf,'type','line');
%     set(h,'linewidth',0.75*scale);
        
    % colorbar 
    l = findobj(gcf,'Type','colorbar');
    if isempty(l) == 0
        set(l,'FontSize',8*scale,'FontName','TimesNewRoman','TickLabelInterpreter','latex') 
        set(l.Label,'FontSize',8*scale,'FontName','TimesNewRoman','Interpreter','latex')
    end

    ha_all = findobj(gcf,'type','axes');    % find all axes in the current figure   
    for index = 1:length(ha_all)
        ha = ha_all(index);
        % Axis tick label
        set(ha,'FontSize',8*scale) 
        set(ha,'FontName','TimesNewRoman','TickLabelInterpreter','latex') % axis font
        
        % Axis title label
        set(ha.YLabel,'FontSize',9*scale,'Interpreter','latex');
        set(ha.XLabel,'FontSize',9*scale,'Interpreter','latex');

        % set grid style
%         set(ha,'xcolor',[0.75 0.75 0.75],'ycolor',[0.75 0.75 0.75])
%         set(ha,'GridLineStyle','-')
%         set(ha,'MinorGridLineStyle','-')
        % set(gca,'MajorGridLineStyle','-')
        grid(ha,'on')
        % c=copyobj(gca,gcf);
        set(ha,'color','none')
%         set(ha,'color','none','xcolor','k','ycolor','k'); % Overwrite color of axes to black
        set(gcf,'color','w');
        box on
    end
end