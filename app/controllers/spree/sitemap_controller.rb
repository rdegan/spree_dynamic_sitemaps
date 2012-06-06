class Spree::SitemapController < Spree::BaseController
  def index
    @public_dir = root_url
    
    @products = Spree::Product.active.find(:all)
    @taxonomies = Spree::Taxonomy.all
    
    # Get Pages from static_content extension
    @pages = _select_static_pages
    
    respond_to do |format|
      format.html {  }
      format.xml do
        nav = _build_taxon_hash
        nav = _build_static_page_hash nav
        nav = _build_post_hash nav
        nav = _add_products_to_tax nav, false
        render :layout => false, :xml => _build_xml(nav, @public_dir)
      end
      format.text do
        @nav = _add_products_to_tax(_build_taxon_hash, false)
        render :layout => false
      end
    end
  end

  private
  def _build_xml(nav, public_dir)
    ''.tap do |output|
      xml = Builder::XmlMarkup.new(:target => output, :indent => 2) 
      xml.instruct!  :xml, :version => "1.0", :encoding => "UTF-8"
      xml.urlset( :xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9" ) {
        xml.url {
          xml.loc public_dir
          xml.lastmod Date.today
          xml.changefreq 'daily'
          xml.priority '1.0'
        }
        nav.each do |k, v| 
          xml.url {
            xml.loc public_dir + v['link']
            xml.lastmod v['updated'].xmlschema			  #change timestamp of last modified
            xml.changefreq 'weekly'
            xml.priority '0.8'
          } 
        end
      }
    end
  end

  def _build_taxon_hash
    nav = Hash.new
    Spree::Taxon.all.each do |taxon|
      tinfo = Hash.new
      tinfo['name'] = taxon.name
      tinfo['depth'] = taxon.permalink.split('/').size
      tinfo['link'] = 't/' + taxon.permalink 
      tinfo['updated'] = taxon.updated_at
      nav[taxon.permalink] = tinfo
    end
    nav
  end

  def _add_products_to_tax(nav, multiples_allowed)
    Spree::Product.active.find(:all).each do |product|
      pinfo = Hash.new
      pinfo['name'] = product.name
      pinfo['link'] = 'products/' + product.permalink	# primary
      pinfo['updated'] = product.updated_at

      nav[pinfo['link']] = pinfo				# store primary
    end
    nav
  end
  
  def _build_pages_hash(nav)
    return nav if @pages.empty?
    
    @pages.each do |page|
      nav[page.slug] = {'name' => page.title,
                        'link' => page.slug.gsub(/^\//, ''),
                        'updated' => page.updated_at}
    end
    nav
  end
  
  def _build_post_hash(nav)
    return nav if Spree::Post.published.empty?
    Spree::Post.published.each do |post|
      nav[post.slug] = {'name' => post.name,
                        'link' => post.slug,
                        'updated' => post.updated_at}
    end
    nav
  end
  
  def _build_static_page_hash(nav)
    return nav if Spree::StaticPage.published.empty?
    Spree::StaticPage.published.each do |page|
      nav[page.slug] = {'name' => page.name,
                        'link' => page.slug,
                        'updated' => page.updated_at}
    end
    nav
  end
  
  def _select_static_pages
    pages = []
    begin
      slugs_to_reject = ["/on-main-page"]
      Spree::Page.visible.each do |page|
        pages << page unless slugs_to_reject.include?(page.slug)
      end
      
    rescue NameError
      pages = []
    end
    pages
  end
end
