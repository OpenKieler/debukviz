package de.cau.cs.kieler.klighd.debug.graphTransformations.lGraph

import de.cau.cs.kieler.core.kgraph.KNode
import de.cau.cs.kieler.core.krendering.LineStyle
import de.cau.cs.kieler.core.krendering.extensions.KColorExtensions
import de.cau.cs.kieler.core.krendering.extensions.KEdgeExtensions
import de.cau.cs.kieler.core.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.core.krendering.extensions.KPolylineExtensions
import de.cau.cs.kieler.core.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.kiml.options.LayoutOptions
import de.cau.cs.kieler.kiml.util.KimlUtil
import javax.inject.Inject
import org.eclipse.debug.core.model.IVariable
import de.cau.cs.kieler.core.krendering.KRendering
import de.cau.cs.kieler.core.krendering.KContainerRendering
import de.cau.cs.kieler.klighd.debug.graphTransformations.AbstractKielerGraphTransformation

import de.cau.cs.kieler.kiml.options.EdgeLabelPlacement
import de.cau.cs.kieler.kiml.options.Direction
import de.cau.cs.kieler.kiml.options.LayoutOptions

import static de.cau.cs.kieler.klighd.debug.visualization.AbstractDebugTransformation.*
import de.cau.cs.kieler.core.krendering.extensions.KLabelExtensions

class LGraphTransformation extends AbstractKielerGraphTransformation {
    
    @Inject
    extension KNodeExtensions
    @Inject
    extension KEdgeExtensions
    @Inject 
    extension KPolylineExtensions 
    @Inject
    extension KRenderingExtensions
    @Inject
    extension KColorExtensions
    @Inject
    extension KLabelExtensions
    /**
     * {@inheritDoc}
     */
	override transform(IVariable graph, Object transformationInfo) {
        if(transformationInfo instanceof Boolean) detailedView = transformationInfo as Boolean
        
        return KimlUtil::createInitializedNode => [
            it.addLayoutParam(LayoutOptions::ALGORITHM, "de.cau.cs.kieler.kiml.ogdf.planarization")
            it.addLayoutParam(LayoutOptions::SPACING, 75f)
            
            // create header node
     		it.createHeaderNode(graph)
     		
     		// add the propertyMap and visualization, if in detailed mode
      		if (detailedView) {
                // add propertyMap
                it.addPropertyMapAndEdge(graph.getVariable("propertyMap"), graph)
                
                // create the visualization
          		it.createAllNodes(graph)
    
                // create all edges, first for all layerlessNodes, then iterate through all layers
          		it.createEdges(graph.getVariable("layerlessNodes"))
          		graph.getVariable("layers").linkedList.forEach[IVariable layer |
          			it.createEdges(layer)	
          		]
            }
        ]
	}
	
	def createHeaderNode(KNode rootNode, IVariable graph) {
		rootNode.addNewNodeById(graph) => [
    		it.data += renderingFactory.createKRectangle => [
    		    it.headerNodeBasics(detailedView, graph)
                
                // id of graph
                it.children += createKText(graph, "id", "", ": ")
                
                // hashCode of graph
                it.children += createKText(graph, "hashCode", "", ": ")
    			
    			if(detailedView) {
                    // hashCodeCounter of graph
                    it.children += renderingFactory.createKText => [
                        it.text = "hashCodeCounter: " + graph.getValue("hashCodeCounter.count")
                    ]
                    
                    // size of graph
                    it.children += renderingFactory.createKText => [
                        it.text = "size (x,y): (" + graph.getValue("size.x").round + " x " 
                                                  + graph.getValue("size.y").round + ")" 
                    ]
                    
                    // insets of graph
                    it.children += renderingFactory.createKText => [
                        it.text = "insets (t,r,b,l): (" + graph.getValue("insets.top").round + " x "
                                                        + graph.getValue("insets.right").round + " x "
                                                        + graph.getValue("insets.bottom").round + " x "
                                                        + graph.getValue("insets.left").round + ")"
                    ]
                    
                    // offset of graph
                    it.children += renderingFactory.createKText => [
                        it.text = "offset (x,y): (" + graph.getValue("offset.x").round + " x "
                                                    + graph.getValue("offset.y").round + ")"
                    ]
    			} else {
    			    // # of nodes
                    it.children += renderingFactory.createKText => [
                        var count = Integer::parseInt(graph.getValue("layerlessNodes.size"))
                        for(layer : graph.getVariable("layers").linkedList) {
                            count = count + Integer::parseInt(layer.getValue("nodes.size"))
                        }
                        it.text = "nodes (#): " + count
                    ]
    			    
    			    // # of layers
                    it.children += renderingFactory.createKText => [
                        it.text = "layers (#): " + graph.getValue("layers.size")
                    ]
    			}
            ]
		]
	}

	def createAllNodes(KNode rootNode, IVariable graph) {
	    // create a node (visualization) containing the graphical visualisation of the LGraph
		// the node has to be registered to a specific object.
		// we are using the layerlessNodes element here
		val visualization = graph.getVariable("layerlessNodes")
        rootNode.addNodeById(visualization) => [
            it.data += renderingFactory.createKRectangle => [
                it.lineWidth = 4
            ]
            // create all nodes (layerless and layered)
	  		it.createNodes(graph.getVariable("layerlessNodes"))
	  		for (layer : graph.getVariable("layers").linkedList) {
	  		    it.createNodes(layer.getVariable("nodes"))
	  		}
  		]
	    // create edge from graph to visualization
        graph.createEdgeById(visualization) => [
            it.data += renderingFactory.createKPolyline => [
                it.setLineWidth(2)
                it.addArrowDecorator
                it.setLineStyle(LineStyle::SOLID)
            ]
            visualization.createLabel(it) => [
                it.addLayoutParam(LayoutOptions::EDGE_LABEL_PLACEMENT, EdgeLabelPlacement::CENTER)
                it.setLabelSize(50,20)
                it.text = "visualization"
            ]
        ]   
	}
	
	def createNodes(KNode rootNode, IVariable nodes) {
	    nodes.linkedList.forEach[IVariable node |
          rootNode.nextTransformation(node, false)
        ]
	}

    def createEdges(KNode rootNode, IVariable layer) {
        layer.linkedList.forEach[IVariable node |
        	node.getVariable("ports").linkedList.forEach[IVariable port |
        		port.getVariable("outgoingEdges").linkedList.forEach[IVariable edge |
                    edge.getVariable("source.owner")
                        .createEdgeById(edge.getVariable("target.owner")) => [
        				it.data += renderingFactory.createKPolyline => [
	            		    it.setLineWidth(2)
                            it.addArrowDecorator
                            
                            switch edge.edgeType {
                                case "COMPOUND_DUMMY" : it.setLineStyle(LineStyle::DASH)
                                case "COMPOUND_SIDE" : it.setLineStyle(LineStyle::DOT)
                                default : it.setLineStyle(LineStyle::SOLID)
                            }
    	    			]
        			]
        		]
        	]
        ]
    }
    
    def getEdgeType(IVariable edge) {
    	val type = edge.getVariable("propertyMap").getValFromHashMap("EDGE_TYPE")
    	if (type == null) {
	        return "NORMAL"
    	} else {
	        return type.getValue("name")   
    	}
    }
}





