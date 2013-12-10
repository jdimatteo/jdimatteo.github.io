/* 

- allow user to view cold spots instead (or in addition to)
- label centromere
- draw boxes around biggest hot spots
    - again allow user to control, maybe selecting how many hottest/coldest bins
      to highlight, and whether or not to include centromere
  
possible user inputs:
- 1. zoom
- 2. pan
- 3. select chromosome(s)
- select cell types
- select screen size (or maybe automatically fill screen)
- re-order chromosomes (if multiple chromosomes displayed)
- ignore centromere (and possibly configure buffer around it)
- ignore beginning/ends (and possibly configure buffer around it)
- percentile vs percent reads
- hot, cold, or both (maybe not both)
- hot/cold cutoff (e.g. only show 97 or higher percentile,
  or .004% or higher reads)

possible additional data to hide/display (possibly according to zoom level),
or maybe to highlight what is being hovered over (e.g. in bottom right of screen)
- bin #
- percent reads
- cell type
- 4. highlight current row and/or bin (e.g. thin horizontal and/or
     rectangular rectangular boxes to highlight hovered position)
      
have a class that represents a chromosome that has a draw method:
  draw(width, height, x, y)
  
drawing method depends on how big it is (e.g. if only a few pixels
tall, then shows cumulative hot spots, but if the whole screen tall,
then breaks down hot spots by cell type).  width determines how
many pixels per bin (if less than 1 pixel per bin, then most extreme
bin is chosen for the pixel (so we don't average out the most
interesting data).
      
drawing method intelligently skips areas that are not on the screen      
- allows zooming     

Pickup here:
  1) allow user to zoom in and pan, intelligently only drawing the right section
  2) show all chromosomes, and allow user to select which to display, intelligently drawing
     a good amount to fit on screen depending on how many chromosomes selected
*/

HScrollbar hotCutoffSlider;
int lastMouseClickMilliseconds = -100;

class CellTypeBins
{
  String cell_type;
  
  // for now, just a single chromosome of percentiles,
  // later we will have percentiles for each chromosome
  ArrayList percentiles = new ArrayList();
}


class Chromosome
{
  ArrayList m_cell_types = new ArrayList();
  
  int m_x;
  int m_y;
  int m_width;
  int m_height;
  
  Chromosome(String a_csv_file, int a_x, int a_y, int a_width, int a_height)
  {
    m_x = a_x;
    m_y = a_y;
    m_width = a_width;
    m_height = a_height;
    
    String[] data = loadStrings(a_csv_file);
    log("there are " + data.length + " lines");
    
    CellTypeBins current = new CellTypeBins();
    
    for (int i=0; i < data.length; ++i)
    {
      String[] record = split(data[i], ',');
      String cell_type = record[0];
      float percentile = float(record[3]);
      if (i == 0)
      {
        current.cell_type = cell_type;
      }
      
      if (current.cell_type != cell_type)
      {
         m_cell_types.add(current);
         current = new CellTypeBins();
         current.cell_type = cell_type;
      }
      
      current.percentiles.add(percentile);
    }
    
    m_cell_types.add(current);
    
    log("there are " + m_cell_types.size() + " cell types, each with "
      + current.percentiles.size() + " bins");
  }
  
  /* shades the bins of the cell types with red being the hottest percentiles
     and white being the least hot percentiles.
     
     @argument hotCutoff determines the max percentile that is drawn as
               pure white (e.g. if .75, then the 75% coldest bins are drawn
               as white, and the 25% hotest bins are drawn shades of red)
   */
  void display(float a_hot_cutoff)
  {
    log("drawing cell types");
    double y = m_y;
    double cell_type_height = (m_height) / m_cell_types.size();
    
    int right_padding_for_labels = 50;
    int left_padding = m_x;
    int max_line_width = m_width-left_padding-right_padding_for_labels;
    int bins = m_cell_types.get(0).percentiles.size();
    int bins_per_pixel = ceil(bins/max_line_width);
    int line_width = bins/bins_per_pixel;
    log("line_width = " + line_width);
    
    log("hotCutoff = " + a_hot_cutoff);
   
    for (int i=0; i<m_cell_types.size(); i++, y+=cell_type_height)
    {
      fill(0);
      CellTypeBins current = m_cell_types.get(i);
      text(current.cell_type, left_padding+line_width+5, y-2);
      stroke(0);
          
      for (int j=0; j <= line_width; j++)
      {
        // if bins_per_pixel > 0, then we don't have enough pixels to display every bin,
        // so we will just display the most interesting (hottest) bin at that pixel
        float maxPercentile = MIN_FLOAT;
        for (k=j*bins_per_pixel; k < (j+1)*bins_per_pixel; k++)
        {
          if (k < current.percentiles.size())
          {
            maxPercentile = max(current.percentiles.get(k), maxPercentile);
          }
        }
        //int redness = map(maxPercentile, 0.0, 100.0, 0, 255);
        //stroke(redness, 0, 0);
        //color between = lerpColor(#296F34, #61E2F0, maxPercentile, HSB);
        
        colorMode(HSB, 100);
              
        if (maxPercentile >= a_hot_cutoff)
        {
          float hotRange = 100-a_hot_cutoff;
          float factor = 100/hotRange;
          stroke(0, (maxPercentile-a_hot_cutoff)*factor, 100);
        }
        else
        {
          stroke(0, 0, 100);
        }
        // todo: try shading based on read percentage instead of percentiles
  
        line(left_padding+j, y, left_padding+j, y-cell_type_height + 1/* +2*/);
      }
    }
  }
}

Chromsome chr1;

PFont font = loadFont("Serif-16");

void log(String message)
{
  bool loggingEnabled = false;
  if (loggingEnabled)
  {
    println(message);
  }
}

void setup()
{
  log("setup");
  size( 900, 400 );
  textFont(font);
  
  chr1 = new Chromosome("normalized_bins_chr1.csv",
                        10, 20, width-10, height-25);
    
  hotCutoffSlider = new HScrollbar(0, height-8, width, 16, 1);
  
  println("Drag to pan and double click to zoom");  
}

/*void mouseScrolled()
{
  // https://processing-js.lighthouseapp.com/projects/41284/tickets/230-mouse-scroll-wheel-support
  
  if (mouseScroll > 0) {
    log("zoom in");
  } else if (mouseScroll < 0) {
    log("zoom out");
  }
}*/

void draw()
{
  log("draw");
  background();
  hotCutoffSlider.update();
  hotCutoffSlider.display();
  
  chr1.display(100*hotCutoffSlider.getValue());
}
